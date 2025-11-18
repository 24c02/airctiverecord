# frozen_string_literal: true

module AirctiveRecord
  module Scoping
    extend ActiveSupport::Concern

    class_methods do
      # returns a chainable Relation object
      def all = relation_class.new(self)

      # scopes are defined on the model's specific Relation class
      def scope(name, body)
        unless body.respond_to?(:call)
          raise ArgumentError, "The scope body needs to be callable."
        end

        # define on the class
        singleton_class.send(:define_method, name) do |*args|
          all.public_send(name, *args)
        end
        
        # define on this model's Relation class
        relation_class.send(:define_method, name) do |*args|
          instance_exec(*args, &body)
        end
      end

      # delegate finder methods to all
      def where(conditions) = all.where(conditions)

      def order(*args) = all.order(*args)

      def limit(value) = all.limit(value)

      def offset(value) = all.offset(value)

      def find_by(conditions) = all.find_by(conditions)

      def find_by!(conditions) = all.find_by!(conditions)

      def first(limit = nil) = all.first(limit)

      def last(limit = nil) = all.last(limit)

      def count = all.count
    end
  end
end
