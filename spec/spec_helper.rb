# frozen_string_literal: true

require "airctiverecord"

# Helper to create test models with proper names
def build_test_model(name = "TestModel", &block)
  Class.new(AirctiveRecord::Base) do
    define_singleton_method(:name) { name }
    class_eval(&block) if block_given?
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
