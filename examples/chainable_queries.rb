#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "airctiverecord"

class User < AirctiveRecord::Base
  self.base_key = "appTest123"
  self.table_name = "Users"

  field :first_name, "First Name"
  field :email, "Email Address"
  field :role, "Role"
  field :active, "Active"
  field :age, "Age"

  scope :active, -> { where(active: true) }
  scope :admins, -> { where(role: "admin") }
  scope :adults, -> { where("AND({Age} >= 18, {Age} < 65)") }
  scope :recent, -> { order(created_at: :desc).limit(10) }

  def self.records(**params)
    puts "Would call Airtable API with:"
    puts params.inspect
    puts
    []
  end
end

puts "=== chainable queries ==="
User.where(role: "admin").where(active: true).order(first_name: :asc).limit(10).to_a
puts

puts "=== scopes chain! ==="
User.active.admins.recent.to_a
puts

puts "=== hash queries with field mappings ==="
User.where(first_name: "Alice", email: "alice@example.com").to_a
puts

puts "=== range queries ==="
User.where(age: 18..65).to_a
puts

puts "=== IN queries ==="
User.where(role: %w[admin moderator guest]).to_a
puts

puts "=== raw formulas still work ==="
User.where("{Age} > 18").where(active: true).to_a
puts

puts "=== lazy loading ==="
query = User.where(role: "admin")
puts "Query built (no API call yet)"
puts "Calling to_airtable:"
puts query.to_airtable
puts "\nNow iterating:"
query.each { |u| puts u }
