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
      validates :email, format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i }, allow_blank: true
      
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
      allow(record).to receive(:_save).and_return(true)
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
end
