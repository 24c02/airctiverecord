# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Field Mappings" do
  let(:model_class) do
    Class.new(AirctiveRecord::Base) do
      self.base_key = "appTest123"
      self.table_name = "Test"

      field :first_name, "First Name"
      field :last_name, "Last Name"
      field :email_address, "Email Address"
      field :is_active, "Active?"
    end
  end

  describe "initialization" do
    it "maps attributes to airtable field names" do
      record = model_class.new(
        first_name: "Alice",
        last_name: "Smith",
        email_address: "alice@example.com"
      )

      expect(record.fields).to eq({
                                    "First Name" => "Alice",
                                    "Last Name" => "Smith",
                                    "Email Address" => "alice@example.com"
                                  })
    end

    it "handles symbol keys" do
      record = model_class.new(first_name: "Bob")
      expect(record.first_name).to eq("Bob")
    end

    it "handles string keys" do
      record = model_class.new("first_name" => "Charlie")
      expect(record.first_name).to eq("Charlie")
    end
  end

  describe "attribute accessors" do
    let(:record) { model_class.new(first_name: "Alice", last_name: "Smith") }

    it "provides getter methods" do
      expect(record.first_name).to eq("Alice")
      expect(record.last_name).to eq("Smith")
    end

    it "provides setter methods" do
      record.first_name = "Alicia"
      expect(record.first_name).to eq("Alicia")
      expect(record.fields["First Name"]).to eq("Alicia")
    end

    it "provides presence check methods" do
      expect(record.first_name?).to be true
      expect(record.email_address?).to be false
    end
  end

  describe "dirty tracking" do
    let(:record) { model_class.new(first_name: "Alice") }

    it "tracks changes" do
      record.first_name = "Alicia"

      expect(record.first_name_changed?).to be true
      expect(record.first_name_was).to eq("Alice")
      expect(record.first_name_change).to eq(%w[Alice Alicia])
    end

    it "doesn't mark as changed if value is same" do
      record.first_name = "Alice"
      expect(record.first_name_changed?).to be false
    end
  end

  describe "field_mappings class method" do
    it "stores mappings" do
      mappings = model_class.field_mappings

      expect(mappings["first_name"]).to eq("First Name")
      expect(mappings["last_name"]).to eq("Last Name")
      expect(mappings["email_address"]).to eq("Email Address")
      expect(mappings["is_active"]).to eq("Active?")
    end
  end
end
