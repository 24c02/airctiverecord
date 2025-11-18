# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Relation" do
  let(:model_class) do
    Class.new(AirctiveRecord::Base) do
      self.base_key = "appTest123"
      self.table_name = "Users"
      
      field :first_name, "First Name"
      field :email, "Email Address"
      field :role, "Role"
      field :active, "Active"
      
      def self.records(**params)
        @last_params = params
        []
      end
      
      def self.last_params
        @last_params
      end
    end
  end

  describe "chainable queries" do
    it "returns a relation from where" do
      result = model_class.where(role: "admin")
      expect(result).to be_a(AirctiveRecord::Relation)
    end

    it "chains multiple where clauses" do
      relation = model_class.where(role: "admin").where(active: true)
      relation.to_a
      
      params = model_class.last_params
      expect(params[:filter]).to eq("AND({Role} = 'admin', {Active} = TRUE())")
    end

    it "uses field mappings in queries" do
      relation = model_class.where(first_name: "Alice", email: "alice@example.com")
      relation.to_a
      
      params = model_class.last_params
      expect(params[:filter]).to include("{First Name} = 'Alice'")
      expect(params[:filter]).to include("{Email Address} = 'alice@example.com'")
    end

    it "applies field mappings to order clauses" do
      relation = model_class.order(:first_name)
      relation.to_a
      
      params = model_class.last_params
      expect(params[:sort]).to eq([{ field: "First Name", direction: "asc" }])
    end
  end

  describe "scopes" do
    before do
      model_class.class_eval do
        scope :active, -> { where(active: true) }
        scope :admins, -> { where(role: "admin") }
        scope :recent, -> { order(:created_at).limit(10) }
      end
    end

    it "defines scope methods on the class" do
      expect(model_class).to respond_to(:active)
      expect(model_class).to respond_to(:admins)
    end

    it "returns a relation from scopes" do
      expect(model_class.active).to be_a(AirctiveRecord::Relation)
    end

    it "chains scopes" do
      relation = model_class.active.admins
      relation.to_a
      
      params = model_class.last_params
      expect(params[:filter]).to eq("AND({Active} = TRUE(), {Role} = 'admin')")
    end

    it "defines scopes on relation class" do
      relation = model_class.where(role: "user")
      expect(relation).to respond_to(:active)
    end
  end

  describe "scope isolation" do
    let(:other_class) do
      Class.new(AirctiveRecord::Base) do
        self.base_key = "appTest123"
        self.table_name = "Posts"
        
        scope :published, -> { where(status: "published") }
        
        def self.records(**params)
          []
        end
      end
    end

    it "keeps scopes isolated per model" do
      expect(model_class.relation_class).not_to eq(other_class.relation_class)
      expect(model_class.all).not_to respond_to(:published)
      expect(other_class.all).to respond_to(:published)
    end
  end

  describe "finder methods" do
    it "delegates first to relation" do
      expect(model_class).to receive(:all).and_call_original
      model_class.first
      
      params = model_class.last_params
      expect(params[:max_records]).to eq(1)
    end

    it "delegates limit to relation" do
      model_class.limit(10).to_a
      
      params = model_class.last_params
      expect(params[:max_records]).to eq(10)
    end

    it "delegates count to relation" do
      allow(model_class).to receive(:records).and_return([1, 2, 3])
      expect(model_class.count).to eq(3)
    end
  end

  describe "find_by" do
    it "finds by hash conditions" do
      allow(model_class).to receive(:records).and_return([double(email: "test@example.com")])
      
      result = model_class.find_by(email: "test@example.com")
      expect(result).to be_present
    end

    it "returns nil if not found" do
      allow(model_class).to receive(:records).and_return([])
      
      result = model_class.find_by(email: "missing@example.com")
      expect(result).to be_nil
    end
  end

  describe "find_by!" do
    it "raises if not found" do
      allow(model_class).to receive(:records).and_return([])
      
      expect {
        model_class.find_by!(email: "missing@example.com")
      }.to raise_error(StandardError, /not found/)
    end
  end
end
