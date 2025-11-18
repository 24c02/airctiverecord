#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "airctiverecord"

# Configure Airtable API
Norairrecord.api_key = ENV.fetch("AIRTABLE_API_KEY")

# Define a User model
class User < AirctiveRecord::Base
  self.base_key = ENV.fetch("AIRTABLE_BASE_KEY")
  self.table_name = "Users"

  # Define attributes
  attribute :name
  attribute :email
  attribute :age
  attribute :role

  # Validations
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :age, numericality: { greater_than: 0, less_than: 150 }, allow_nil: true
  validates :role, inclusion: { in: %w[admin user guest] }, allow_nil: true

  # Callbacks
  before_save :normalize_email
  after_create :log_creation

  # Scopes
  scope :admins, -> { where("{Role} = 'admin'") }
  scope :active, -> { where("{Active} = TRUE()") }

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def log_creation
    puts "Created user: #{name} (#{email})"
  end
end

# Example: Create a new user
puts "Creating a new user..."
user = User.new(
  name: "Alice Smith",
  email: "ALICE@EXAMPLE.COM", # Will be normalized
  age: 30,
  role: "admin"
)

if user.valid?
  puts "User is valid!"
  # Uncomment to actually save:
  # user.save
  # puts "User saved with ID: #{user.id}"
else
  puts "Validation errors:"
  user.errors.full_messages.each { |msg| puts "  - #{msg}" }
end

# Example: Query users
puts "\nQuerying users..."
# Uncomment to run actual queries:
# all_users = User.all
# admin_users = User.admins
# specific_user = User.find_by(email: "alice@example.com")

# Example: Update a user
puts "\nUpdating a user..."
# Uncomment to run:
# user = User.first
# user.update(name: "Alice Johnson")

# Example: Dirty tracking
puts "\nDirty tracking example..."
user.name = "Alice Johnson"
puts "Name changed? #{user.name_changed?}"
puts "Name was: #{user.name_was}"
puts "Name is now: #{user.name}"

# Example: Invalid user
puts "\nTrying to create invalid user..."
invalid_user = User.new(email: "not-an-email")
puts "Valid? #{invalid_user.valid?}"
puts "Errors: #{invalid_user.errors.full_messages.join(", ")}"

puts "\nDone!"
