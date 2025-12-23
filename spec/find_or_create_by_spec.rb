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
        expect(result.id).to eq("rec123")
      end
    end

    context "when record does not exist" do
      it "creates a new record" do
        # Mock save to return true and set id
        allow_any_instance_of(model_class).to receive(:save) do |record|
          record.instance_variable_set(:@id, "rec#{rand(100000)}")
          record.instance_variable_set(:@new_record, false)
          true
        end

        result = model_class.find_or_create_by(email: "new@example.com", name: "Bob")

        expect(result).to be_a(model_class)
        expect(result.email).to eq("new@example.com")
        expect(result.name).to eq("Bob")
        expect(result.id).to be_present
      end

      it "returns the created record even if invalid" do
        result = model_class.find_or_create_by(email: nil, name: "Invalid")

        expect(result).to be_a(model_class)
        expect(result.valid?).to be false
        expect(result.new_record?).to be true
      end
    end

    context "with field mappings" do
      it "uses field mappings in both find and create" do
        # Mock save to return true and set id
        allow_any_instance_of(model_class).to receive(:save) do |record|
          record.instance_variable_set(:@id, "rec#{rand(100000)}")
          record.instance_variable_set(:@new_record, false)
          true
        end

        result = model_class.find_or_create_by(email: "mapped@example.com", name: "Charlie")

        # Check that the find_by was called with conditions
        expect(model_class.last_params[:filter]).to include("{Email Address} = 'mapped@example.com'")
        
        # Check record was created with mapped fields
        expect(result.email).to eq("mapped@example.com")
        expect(result.name).to eq("Charlie")
      end
    end

    context "with a block" do
      it "yields to the block when creating a new record" do
        # Mock save to return true and set id
        allow_any_instance_of(model_class).to receive(:save) do |record|
          record.instance_variable_set(:@id, "rec#{rand(100000)}")
          record.instance_variable_set(:@new_record, false)
          true
        end

        result = model_class.find_or_create_by(email: "block@example.com") do |user|
          user.name = "Block User"
          user.age = 25
        end

        expect(result.email).to eq("block@example.com")
        expect(result.name).to eq("Block User")
        expect(result.age).to eq(25)
      end

      it "does not yield when record exists" do
        existing_record = model_class.new(email: "exists@example.com", name: "Existing")
        existing_record.instance_variable_set(:@id, "rec789")
        existing_record.instance_variable_set(:@new_record, false)
        
        model_class.stub_records = [existing_record]

        block_called = false
        result = model_class.find_or_create_by(email: "exists@example.com") do |user|
          block_called = true
          user.name = "Should Not Change"
        end

        expect(block_called).to be false
        expect(result.name).to eq("Existing")
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
        expect(result.id).to eq("rec456")
      end
    end

    context "when record does not exist" do
      it "creates a new record" do
        # Mock save! to return true and set id
        allow_any_instance_of(model_class).to receive(:save!) do |record|
          record.instance_variable_set(:@id, "rec#{rand(100000)}")
          record.instance_variable_set(:@new_record, false)
          true
        end

        result = model_class.find_or_create_by!(email: "new@example.com", name: "Bob")

        expect(result).to be_a(model_class)
        expect(result.email).to eq("new@example.com")
        expect(result.name).to eq("Bob")
        expect(result.id).to be_present
      end

      it "raises RecordInvalid if validation fails" do
        expect do
          model_class.find_or_create_by!(email: nil, name: "Invalid")
        end.to raise_error(AirctiveRecord::RecordInvalid, /can't be blank/)
      end
    end

    context "with field mappings" do
      it "uses field mappings in both find and create" do
        # Mock save! to return true and set id
        allow_any_instance_of(model_class).to receive(:save!) do |record|
          record.instance_variable_set(:@id, "rec#{rand(100000)}")
          record.instance_variable_set(:@new_record, false)
          true
        end

        result = model_class.find_or_create_by!(email: "mapped2@example.com", name: "Diana")

        # Check that the find_by was called with conditions
        expect(model_class.last_params[:filter]).to include("{Email Address} = 'mapped2@example.com'")
        
        # Check record was created with mapped fields
        expect(result.email).to eq("mapped2@example.com")
        expect(result.name).to eq("Diana")
      end
    end

    context "with a block" do
      it "yields to the block when creating a new record" do
        # Mock save! to return true and set id
        allow_any_instance_of(model_class).to receive(:save!) do |record|
          record.instance_variable_set(:@id, "rec#{rand(100000)}")
          record.instance_variable_set(:@new_record, false)
          true
        end

        result = model_class.find_or_create_by!(email: "block@example.com") do |user|
          user.name = "Block User"
          user.age = 30
        end

        expect(result.email).to eq("block@example.com")
        expect(result.name).to eq("Block User")
        expect(result.age).to eq(30)
      end

      it "does not yield when record exists" do
        existing_record = model_class.new(email: "exists@example.com", name: "Existing")
        existing_record.instance_variable_set(:@id, "rec999")
        existing_record.instance_variable_set(:@new_record, false)
        
        model_class.stub_records = [existing_record]

        block_called = false
        result = model_class.find_or_create_by!(email: "exists@example.com") do |user|
          block_called = true
          user.name = "Should Not Change"
        end

        expect(block_called).to be false
        expect(result.name).to eq("Existing")
      end

      it "raises RecordInvalid with block attributes if validation fails" do
        expect do
          model_class.find_or_create_by!(email: "invalid@example.com") do |user|
            user.email = nil # Make it invalid
          end
        end.to raise_error(AirctiveRecord::RecordInvalid, /can't be blank/)
      end
    end
  end
end
