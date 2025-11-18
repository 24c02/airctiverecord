# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Validations" do
  let(:model_class) do
    build_test_model("TestUser") do
      self.base_key = "appTest123"
      self.table_name = "Users"

      field :name, "Name"
      field :email, "Email"
      field :age, "Age"

      validates :name, presence: true
      validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
      validates :age, numericality: { greater_than: 0 }, allow_nil: true
    end
  end

  describe "presence validation" do
    it "validates presence" do
      record = model_class.new
      expect(record.valid?).to be false
      expect(record.errors[:name]).to include("can't be blank")
    end

    it "passes when value is present" do
      record = model_class.new(name: "Alice")
      record.valid?
      expect(record.errors[:name]).to be_empty
    end
  end

  describe "format validation" do
    it "validates email format" do
      record = model_class.new(name: "Alice", email: "invalid")
      expect(record.valid?).to be false
      expect(record.errors[:email]).to be_present
    end

    it "allows valid email" do
      record = model_class.new(name: "Alice", email: "alice@example.com")
      record.valid?
      expect(record.errors[:email]).to be_empty
    end

    it "allows blank when allow_blank: true" do
      record = model_class.new(name: "Alice", email: "")
      record.valid?
      expect(record.errors[:email]).to be_empty
    end
  end

  describe "numericality validation" do
    it "validates greater than" do
      record = model_class.new(name: "Alice", age: -5)
      expect(record.valid?).to be false
      expect(record.errors[:age]).to be_present
    end

    it "allows valid number" do
      record = model_class.new(name: "Alice", age: 25)
      record.valid?
      expect(record.errors[:age]).to be_empty
    end

    it "allows nil when allow_nil: true" do
      record = model_class.new(name: "Alice", age: nil)
      record.valid?
      expect(record.errors[:age]).to be_empty
    end
  end

  describe "save with validation" do
    it "returns false if invalid" do
      record = model_class.new

      expect(record.save).to be false
    end

    it "saves if valid" do
      record = model_class.new(name: "Alice")
      # stub _create to avoid actual airtable call
      allow(record).to receive(:_create).and_return(nil)

      expect(record.save).to be true
    end
  end

  describe "save! with validation" do
    it "raises if invalid" do
      record = model_class.new

      expect do
        record.save!
      end.to raise_error(AirctiveRecord::RecordInvalid, /can't be blank/)
    end
  end
end
