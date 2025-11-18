#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "airctiverecord"

# Configure Airtable API
Norairrecord.api_key = ENV.fetch("AIRTABLE_API_KEY")
BASE_KEY = ENV.fetch("AIRTABLE_BASE_KEY")

# Define models with associations
class Team < AirctiveRecord::Base
  self.base_key = BASE_KEY
  self.table_name = "Teams"
  
  attribute :name
  attribute :description
  
  has_many :users
  has_one :leader, class_name: "User", foreign_key: "Leader"
  
  validates :name, presence: true
end

class User < AirctiveRecord::Base
  self.base_key = BASE_KEY
  self.table_name = "Users"
  
  attribute :name
  attribute :email
  
  belongs_to :team
  has_many :tasks
  
  validates :name, presence: true
  validates :email, presence: true
end

class Task < AirctiveRecord::Base
  self.base_key = BASE_KEY
  self.table_name = "Tasks"
  
  attribute :title
  attribute :status
  attribute :description
  
  belongs_to :user
  has_one :team, through: :user
  
  validates :title, presence: true
  validates :status, inclusion: { in: %w[pending in_progress completed] }
  
  scope :pending, -> { where("{Status} = 'pending'") }
  scope :completed, -> { where("{Status} = 'completed'") }
end

# Example usage (uncomment to run with actual Airtable data):

# Find a team and its users
# team = Team.first
# puts "Team: #{team.name}"
# puts "Members:"
# team.users.each do |user|
#   puts "  - #{user.name} (#{user.email})"
# end
# puts "Leader: #{team.leader&.name}"

# Find a user and their tasks
# user = User.find_by(email: "alice@example.com")
# puts "\n#{user.name}'s tasks:"
# user.tasks.pending.each do |task|
#   puts "  - #{task.title} [#{task.status}]"
# end

# Create associations
# team = Team.first
# new_user = User.create!(
#   name: "Bob Johnson",
#   email: "bob@example.com",
#   team: team
# )
# puts "Created user #{new_user.name} in team #{team.name}"

# has_many through example
# task = Task.first
# puts "Task '#{task.title}' belongs to team: #{task.team&.name}"

puts "Association examples ready (uncomment code to run)"
