#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "airctiverecord"

class User < AirctiveRecord::Base
  self.base_key = "appTest123"
  self.table_name = "Users"
  
  field :role, "Role"
  field :active, "Active"
  
  scope :active, -> { where(active: true) }
  scope :admins, -> { where(role: "admin") }
  
  def self.records(**params)
    puts "User.records called with: #{params.inspect}"
    []
  end
end

class Post < AirctiveRecord::Base
  self.base_key = "appTest123"
  self.table_name = "Posts"
  
  field :status, "Status"
  field :featured, "Featured"
  
  scope :published, -> { where(status: "published") }
  scope :featured, -> { where(featured: true) }
  
  def self.records(**params)
    puts "Post.records called with: #{params.inspect}"
    []
  end
end

puts "=== User has its own scopes ==="
puts "User relation class: #{User.relation_class.object_id}"
puts "User scopes: #{User.relation_class.instance_methods(false).sort}"
puts

puts "=== Post has its own scopes ==="
puts "Post relation class: #{Post.relation_class.object_id}"
puts "Post scopes: #{Post.relation_class.instance_methods(false).sort}"
puts

puts "=== Different relation classes ==="
puts "Same class? #{User.relation_class == Post.relation_class}"
puts

puts "=== User.active.admins ==="
User.active.admins.to_a
puts

puts "=== Post.published.featured ==="
Post.published.featured.to_a
puts

puts "=== Trying to call Post scope on User (should fail) ==="
begin
  User.all.published.to_a
  puts "ERROR: Should have raised NoMethodError!"
rescue NoMethodError => e
  puts "✓ Correctly raised: #{e.message}"
end
