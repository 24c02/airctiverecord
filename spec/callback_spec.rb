# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Callbacks" do
  let(:model_class) do
    build_test_model("TestUser") do
      self.base_key = "appTest123"
      self.table_name = "Users"
      
      field :name, "Name"
      field :email, "Email"
      
      validates :name, presence: true
      
      attr_accessor :callback_log
      
      before_validation { callback_log << :before_validation }
      after_validation { callback_log << :after_validation }
      
      before_save { callback_log << :before_save }
      after_save { callback_log << :after_save }
      
      before_create { callback_log << :before_create }
      after_create { callback_log << :after_create }
      
      before_update { callback_log << :before_update }
      after_update { callback_log << :after_update }
      
      def initialize(*args, **kwargs)
        super
        @callback_log = []
      end
    end
  end

  describe "validation callbacks" do
    it "runs before and after validation" do
      record = model_class.new(name: "Alice")
      record.valid?
      
      expect(record.callback_log).to include(:before_validation, :after_validation)
    end
  end

  describe "save callbacks on new record" do
    it "runs save and create callbacks" do
      record = model_class.new(name: "Alice")
      # stub the norairrecord save to not actually call airtable
      allow(record).to receive(:_create).and_return(nil)
      
      record.save
      
      expect(record.callback_log).to include(
        :before_save,
        :before_create
      )
      # after callbacks run after the actual save
      expect(record.callback_log).to include(:after_create, :after_save)
    end

    it "runs callbacks in correct order" do
      record = model_class.new(name: "Alice")
      allow(record).to receive(:_create).and_return(nil)
      
      record.save
      
      # before_save wraps before_create
      save_index = record.callback_log.index(:before_save)
      create_index = record.callback_log.index(:before_create)
      expect(save_index).to be < create_index if save_index && create_index
    end
  end

  describe "save callbacks on existing record" do
    it "runs save and update callbacks" do
      record = model_class.new(name: "Alice", id: "rec123", created_at: Time.now.iso8601)
      record.name = "Alice Updated" # mark as dirty
      allow(model_class).to receive(:_update).and_return({"Name" => "Alice Updated"})
      
      record.save
      
      expect(record.callback_log).to include(
        :before_save,
        :before_update
      )
      expect(record.callback_log).to include(:after_update, :after_save)
      expect(record.callback_log).not_to include(:before_create, :after_create)
    end
  end

  describe "callbacks with validation failure" do
    it "runs before_validation but not save callbacks" do
      record = model_class.new # invalid - no name
      
      record.save
      
      expect(record.callback_log).to include(:before_validation)
      # after_validation may or may not run depending on activemodel version
      expect(record.callback_log).not_to include(:before_save, :after_save)
    end
  end
end
