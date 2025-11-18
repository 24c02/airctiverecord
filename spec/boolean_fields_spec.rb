# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Boolean fields" do
  let(:model_class) do
    build_test_model("BooleanTest") do
      self.base_key = "appTest123"
      self.table_name = "Test"

      field :name, "Name"
      field :active, "Active", type: :boolean
      field :verified, "Verified", type: :boolean

      scope :active, -> { where(active: true) }
    end
  end

  describe "? method for boolean fields" do
    it "returns boolean value when true" do
      record = model_class.new(active: true)
      expect(record.active?).to be true
    end

    it "returns boolean value when false" do
      record = model_class.new(active: false)
      expect(record.active?).to be false
    end

    it "returns false when nil" do
      record = model_class.new(active: nil)
      expect(record.active?).to be false
    end
  end

  describe "? method for non-boolean fields" do
    it "checks presence" do
      record = model_class.new(name: "Alice")
      expect(record.name?).to be true
    end

    it "returns false for empty string" do
      record = model_class.new(name: "")
      expect(record.name?).to be false
    end

    it "returns false for nil" do
      record = model_class.new(name: nil)
      expect(record.name?).to be false
    end
  end

  describe "scopes with boolean fields" do
    it "builds correct formula" do
      allow(model_class).to receive(:records) do |**params|
        expect(params[:filter]).to eq("{Active} = TRUE()")
        []
      end

      model_class.active.to_a
    end
  end
end
