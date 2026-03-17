# frozen_string_literal: true

require "spec_helper"

RSpec.describe AirctiveRecord::Base do
  let(:test_class) do
    build_test_model("TestUser") do
      self.base_key = "appTest123"
      self.table_name = "Test"

      attribute :name
      attribute :email
      attribute :age

      validates :name, presence: true
      validates :email, format: { with: /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i }, allow_blank: true

      before_save :normalize_name

      def normalize_name
        self.name = name&.strip
      end
    end
  end

  describe "ActiveModel integration" do
    it "includes validations" do
      record = test_class.new
      expect(record.valid?).to be false
      expect(record.errors[:name]).to include("can't be blank")
    end

    it "validates email format" do
      record = test_class.new(name: "Test", email: "invalid")
      expect(record.valid?).to be false
      expect(record.errors[:email]).to be_present
    end
  end

  describe "attributes" do
    it "defines attribute accessors" do
      record = test_class.new(name: "Alice", email: "alice@example.com")
      expect(record.name).to eq("Alice")
      expect(record.email).to eq("alice@example.com")
    end

    it "tracks dirty attributes" do
      record = test_class.new(name: "Alice")
      record.name = "Bob"
      expect(record.name_changed?).to be true
      expect(record.name_was).to eq("Alice")
    end
  end

  describe "callbacks" do
    it "runs before_save callback" do
      record = test_class.new(name: "  Alice  ")
      allow(record).to receive(:_create).and_return(true)
      record.save
      expect(record.name).to eq("Alice")
    end
  end

  describe "ActiveRecord-like methods" do
    it "responds to persisted?" do
      record = test_class.new(name: "Alice")
      expect(record.persisted?).to be false
    end

    it "responds to to_param" do
      record = test_class.new(name: "Alice", id: "rec123")
      expect(record.to_param).to eq("rec123")
    end
  end

  # Issue #3: ActionController::Parameters silently dropped
  describe "#initialize with non-Hash objects that respond to to_h" do
    it "accepts ActionController::Parameters-like objects (non-Hash with to_h)" do
      # Simulate ActionController::Parameters which is NOT a Hash subclass
      fake_params = Object.new
      def fake_params.to_h
        { "name" => "Alice", "email" => "alice@example.com" }
      end

      record = test_class.new(fake_params)
      expect(record.name).to eq("Alice")
      expect(record.email).to eq("alice@example.com")
    end

    it "still works with a plain Hash" do
      record = test_class.new("name" => "Bob", "email" => "bob@example.com")
      expect(record.name).to eq("Bob")
      expect(record.email).to eq("bob@example.com")
    end
  end

  # Issue #4: save rescues all StandardError, swallowing API errors
  describe "#save error propagation" do
    it "lets API errors propagate instead of returning false" do
      record = test_class.new(name: "Alice")
      allow(record).to receive(:_create).and_raise(RuntimeError, "Airtable API error")

      expect { record.save }.to raise_error(RuntimeError, "Airtable API error")
    end

    it "still returns false for validation failures" do
      record = test_class.new # no name, fails validation
      expect(record.save).to be false
    end
  end

  describe "#save! error propagation" do
    it "propagates the underlying API error rather than wrapping it in RecordNotSaved" do
      record = test_class.new(name: "Alice")
      allow(record).to receive(:_create).and_raise(RuntimeError, "Airtable API error")

      expect { record.save! }.to raise_error(RuntimeError, "Airtable API error")
    end
  end

  # Issue #1: find_or_create_by / find_or_create_by!
  describe ".find_or_create_by" do
    it "returns the existing record when one is found" do
      existing = test_class.new(name: "Alice")
      allow(test_class).to receive(:find_by).with({ name: "Alice" }).and_return(existing)

      result = test_class.find_or_create_by(name: "Alice")
      expect(result).to be existing
    end

    it "creates and returns a new record when none is found" do
      allow(test_class).to receive(:find_by).with({ name: "Alice" }).and_return(nil)
      new_record = test_class.new(name: "Alice")
      allow(test_class).to receive(:new).with({ name: "Alice" }).and_return(new_record)
      allow(new_record).to receive(:save).and_return(true)

      result = test_class.find_or_create_by(name: "Alice")
      expect(result).to be new_record
      expect(new_record).to have_received(:save)
    end

    it "returns the new (unsaved) record even if save fails" do
      allow(test_class).to receive(:find_by).and_return(nil)
      new_record = test_class.new # invalid: no name
      allow(test_class).to receive(:new).and_return(new_record)

      result = test_class.find_or_create_by(name: nil)
      expect(result).to be new_record
      expect(result.persisted?).to be false
    end

    it "yields the new record to a block before saving" do
      allow(test_class).to receive(:find_by).and_return(nil)
      new_record = test_class.new(name: "Alice")
      allow(test_class).to receive(:new).and_return(new_record)
      allow(new_record).to receive(:save).and_return(true)

      yielded = nil
      test_class.find_or_create_by(name: "Alice") { |r| yielded = r }
      expect(yielded).to be new_record
    end

    it "does not yield the block when the record already exists" do
      existing = test_class.new(name: "Alice")
      allow(test_class).to receive(:find_by).and_return(existing)

      yielded = false
      test_class.find_or_create_by(name: "Alice") { yielded = true }
      expect(yielded).to be false
    end
  end

  describe ".find_or_create_by!" do
    it "returns the existing record when one is found" do
      existing = test_class.new(name: "Alice")
      allow(test_class).to receive(:find_by).with({ name: "Alice" }).and_return(existing)

      result = test_class.find_or_create_by!(name: "Alice")
      expect(result).to be existing
    end

    it "raises RecordInvalid when the new record is invalid" do
      allow(test_class).to receive(:find_by).and_return(nil)

      expect { test_class.find_or_create_by!(name: nil) }.to raise_error(AirctiveRecord::RecordInvalid)
    end

    it "raises API errors when save! fails at the storage layer" do
      allow(test_class).to receive(:find_by).and_return(nil)
      new_record = test_class.new(name: "Alice")
      allow(test_class).to receive(:new).and_return(new_record)
      allow(new_record).to receive(:_create).and_raise(RuntimeError, "Airtable API error")

      expect { test_class.find_or_create_by!(name: "Alice") }.to raise_error(RuntimeError, "Airtable API error")
    end

    it "yields the new record to a block before saving" do
      allow(test_class).to receive(:find_by).and_return(nil)
      new_record = test_class.new(name: "Alice")
      allow(test_class).to receive(:new).and_return(new_record)
      allow(new_record).to receive(:save!).and_return(true)

      yielded = nil
      test_class.find_or_create_by!(name: "Alice") { |r| yielded = r }
      expect(yielded).to be new_record
    end

    it "does not yield the block when the record already exists" do
      existing = test_class.new(name: "Alice")
      allow(test_class).to receive(:find_by).and_return(existing)

      yielded = false
      test_class.find_or_create_by!(name: "Alice") { yielded = true }
      expect(yielded).to be false
    end
  end
end
