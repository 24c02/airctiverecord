# frozen_string_literal: true

require "spec_helper"

RSpec.describe "find_or_create_by" do
  let(:model_class) do
    build_test_model("TestUser") do
      self.base_key = "appTest123"
      self.table_name = "Users"

      field :email, "Email Address"
      field :name, "Name"
      field :age, "Age"

      validates :email, presence: true
      validates :age, numericality: { greater_than: 0 }, allow_nil: true

      # Track created records
      @created_records = []

      def self.create(attributes)
        record = new(attributes)
        if record.valid?
          record.instance_variable_set(:@id, "rec#{rand(100000)}")
          record.instance_variable_set(:@new_record, false)
          @created_records << record
          record
        else
          record
        end
      end

      def self.create!(attributes)
        record = new(attributes)
        if record.valid?
          record.instance_variable_set(:@id, "rec#{rand(100000)}")
          record.instance_variable_set(:@new_record, false)
          @created_records << record
          record
        else
          raise AirctiveRecord::RecordInvalid, record.errors.full_messages.join(", ")
        end
      end

      def self.created_records
        @created_records
      end

      def self.reset_created_records
        @created_records = []
      end

      def self.records(**params)
        @last_params = params
        @stub_records || []
      end

      class << self
        attr_reader :last_params
        attr_accessor :stub_records
      end
    end
  end

  before do
    model_class.reset_created_records
    model_class.stub_records = []
  end

  describe "#find_or_create_by" do
    context "when record exists" do
      it "returns the existing record" do
        existing_record = model_class.new(email: "test@example.com", name: "Alice")
        existing_record.instance_variable_set(:@id, "rec123")
        existing_record.instance_variable_set(:@new_record, false)
        
        model_class.stub_records = [existing_record]

        result = model_class.find_or_create_by(email: "test@example.com")

        expect(result).to eq(existing_record)
        expect(model_class.created_records).to be_empty
      end
    end

    context "when record does not exist" do
      it "creates a new record" do
        model_class.stub_records = []

        result = model_class.find_or_create_by(email: "new@example.com", name: "Bob")

        expect(result).to be_a(model_class)
        expect(result.email).to eq("new@example.com")
        expect(result.name).to eq("Bob")
        expect(result.id).to be_present
        expect(model_class.created_records.size).to eq(1)
      end

      it "returns the created record even if invalid" do
        model_class.stub_records = []

        result = model_class.find_or_create_by(email: nil, name: "Invalid")

        expect(result).to be_a(model_class)
        expect(result.valid?).to be false
        expect(result.new_record?).to be true
      end
    end

    context "with field mappings" do
      it "uses field mappings in both find and create" do
        model_class.stub_records = []

        result = model_class.find_or_create_by(email: "mapped@example.com", name: "Charlie")

        # Check that the find_by was called with conditions
        expect(model_class.last_params[:filter]).to include("{Email Address} = 'mapped@example.com'")
        
        # Check record was created with mapped fields
        expect(result.email).to eq("mapped@example.com")
        expect(result.name).to eq("Charlie")
      end
    end
  end

  describe "#find_or_create_by!" do
    context "when record exists" do
      it "returns the existing record" do
        existing_record = model_class.new(email: "test@example.com", name: "Alice")
        existing_record.instance_variable_set(:@id, "rec456")
        existing_record.instance_variable_set(:@new_record, false)
        
        model_class.stub_records = [existing_record]

        result = model_class.find_or_create_by!(email: "test@example.com")

        expect(result).to eq(existing_record)
        expect(model_class.created_records).to be_empty
      end
    end

    context "when record does not exist" do
      it "creates a new record" do
        model_class.stub_records = []

        result = model_class.find_or_create_by!(email: "new@example.com", name: "Bob")

        expect(result).to be_a(model_class)
        expect(result.email).to eq("new@example.com")
        expect(result.name).to eq("Bob")
        expect(result.id).to be_present
        expect(model_class.created_records.size).to eq(1)
      end

      it "raises RecordInvalid if validation fails" do
        model_class.stub_records = []

        expect do
          model_class.find_or_create_by!(email: nil, name: "Invalid")
        end.to raise_error(AirctiveRecord::RecordInvalid, /can't be blank/)
      end
    end

    context "with field mappings" do
      it "uses field mappings in both find and create" do
        model_class.stub_records = []

        result = model_class.find_or_create_by!(email: "mapped2@example.com", name: "Diana")

        # Check that the find_by was called with conditions
        expect(model_class.last_params[:filter]).to include("{Email Address} = 'mapped2@example.com'")
        
        # Check record was created with mapped fields
        expect(result.email).to eq("mapped2@example.com")
        expect(result.name).to eq("Diana")
      end
    end
  end
end
