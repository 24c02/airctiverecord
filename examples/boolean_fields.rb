#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "airctiverecord"

class User < AirctiveRecord::Base
  self.base_key = "appTest123"
  self.table_name = "Users"

  field :name, "Name"
  field :email, "Email"
  field :active, "Active", type: :boolean
  field :verified, "Verified", type: :boolean
  field :admin, "Admin", type: :boolean

  scope :active, -> { where(active: true) }
  scope :verified, -> { where(verified: true) }
  scope :admins, -> { where(admin: true) }

  def self.records(**params)
    puts "records(#{params.inspect})"
    []
  end
end

puts "=== boolean field with type: :boolean ==="
user = User.new(
  name: "Alice",
  active: true,
  verified: false,
  admin: nil
)

puts "active: #{user.active.inspect}"
puts "active?: #{user.active?}"

puts "\nverified: #{user.verified.inspect}"
puts "verified?: #{user.verified?}"

puts "\nadmin (nil): #{user.admin.inspect}"
puts "admin?: #{user.admin?} (falsy)"

puts "\n=== regular field (no type specified) ==="
puts "name: #{user.name.inspect}"
puts "name?: #{user.name?} (presence check)"

puts "\n=== scopes with booleans ==="
User.active.to_a
puts

User.active.verified.admins.to_a
