#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "airctiverecord"

class AirpplicationRecord < AirctiveRecord::Base
  self.base_key = "appTest123"
end

class Contact < AirpplicationRecord
  self.table_name = "Contacts"
  
  field :name, "Name"
  field :email, "Email"
  field :company, "Company"
  
  # lookup fields (pulled from linked Company record)
  field :company_name, "Company Name (from Company)", readonly: true
  field :company_address, "Company Address (from Company)", readonly: true
  
  # formula fields (computed by airtable)
  field :full_name, "Full Name (formula)", readonly: true
end

contact = Contact.new(
  name: "Alice",
  email: "alice@example.com",
  company_name: "Acme Corp"  # readonly field - silently ignored
)

puts "=== readonly fields are readable ==="
contact.instance_variable_set(:@fields, {
  "Name" => "Alice",
  "Email" => "alice@example.com",
  "Company Name (from Company)" => "Acme Corp",
  "Full Name (formula)" => "Alice Smith"
})

puts "company_name: #{contact.company_name}"
puts "full_name: #{contact.full_name}"

puts "\n=== trying to set readonly field ==="
contact.company_name = "Evil Corp"
puts "company_name after set: #{contact.company_name} (unchanged)"

puts "\n=== serializable_fields excludes readonly ==="
puts "fields: #{contact.fields.keys}"
puts "serializable_fields: #{contact.serializable_fields.keys}"

puts "\n=== readonly_fields list ==="
puts "Contact.readonly_fields: #{Contact.readonly_fields.to_a.inspect}"
