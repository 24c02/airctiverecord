#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "airctiverecord"

# Configure Airtable API
Norairrecord.api_key = ENV.fetch("AIRTABLE_API_KEY", "test_key")

# Example: Mapping Airtable fields with spaces to Ruby-friendly names
class Contact < AirctiveRecord::Base
  self.base_key = ENV.fetch("AIRTABLE_BASE_KEY", "appTest123")
  self.table_name = "Contacts"
  
  # Map Ruby attribute names to Airtable field names with spaces
  field :first_name, "First Name"
  field :last_name, "Last Name"
  field :email_address, "Email Address"
  field :phone_number, "Phone Number (Mobile)"
  field :company_name, "Company Name"
  field :job_title, "Job Title"
  field :linkedin_url, "LinkedIn URL"
  field :date_added, "Date Added"
  field :is_vip, "VIP?"
  
  # Validations using Ruby attribute names
  validates :first_name, :last_name, presence: true
  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone_number, length: { minimum: 10 }, allow_blank: true
  
  # Callbacks
  before_save :normalize_email
  
  # Scopes
  scope :vip, -> { where("{VIP?} = TRUE()") }
  scope :with_email, -> { where("{Email Address} != ''") }
  
  private
  
  def normalize_email
    self.email_address = email_address&.downcase&.strip
  end
end

# Example usage
puts "Creating a contact with field mappings..."
contact = Contact.new(
  first_name: "Jane",
  last_name: "Smith",
  email_address: "JANE.SMITH@EXAMPLE.COM",
  phone_number: "555-123-4567",
  company_name: "Acme Corp",
  job_title: "Senior Engineer",
  is_vip: true
)

puts "\nContact attributes (Ruby names):"
puts "  First Name: #{contact.first_name}"
puts "  Last Name: #{contact.last_name}"
puts "  Email: #{contact.email_address}"
puts "  Phone: #{contact.phone_number}"
puts "  Company: #{contact.company_name}"
puts "  VIP?: #{contact.is_vip}"

puts "\nValidation:"
if contact.valid?
  puts "  ✓ Contact is valid"
else
  puts "  ✗ Validation errors:"
  contact.errors.full_messages.each { |msg| puts "    - #{msg}" }
end

puts "\nDirty tracking with field mappings:"
contact.first_name = "Janet"
puts "  first_name changed? #{contact.first_name_changed?}"
puts "  first_name was: #{contact.first_name_was}"
puts "  first_name is now: #{contact.first_name}"
puts "  Changes: #{contact.changes.inspect}"

puts "\nPresence checking:"
puts "  first_name present? #{contact.first_name?}"
puts "  linkedin_url present? #{contact.linkedin_url?}"

puts "\nActual Airtable fields (what gets sent to Airtable):"
puts "  #{contact.fields.inspect}"

puts "\nField mappings:"
puts "  #{Contact.field_mappings.inspect}"

# Example with invalid data
puts "\n\nCreating invalid contact..."
invalid_contact = Contact.new(
  email_address: "not-an-email",
  phone_number: "123" # too short
)

puts "Valid? #{invalid_contact.valid?}"
puts "Errors:"
invalid_contact.errors.full_messages.each { |msg| puts "  - #{msg}" }

puts "\nDone!"
