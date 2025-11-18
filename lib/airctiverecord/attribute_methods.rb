# frozen_string_literal: true

module AirctiveRecord
  module AttributeMethods
    extend ActiveSupport::Concern

    included do
      include ActiveModel::AttributeMethods
    end

    class_methods do
      def field_mappings
        @field_mappings ||= {}
      end

      def readonly_fields
        @readonly_fields ||= Set.new
      end

      def field(attr_name, airtable_field_name = nil, **options)
        attr_name = attr_name.to_s
        airtable_field_name ||= attr_name
        readonly = options[:readonly] || options[:read_only]
        field_type = options[:type]

        field_mappings[attr_name] = airtable_field_name
        readonly_fields << airtable_field_name if readonly

        define_attribute_methods attr_name

        define_method(attr_name) do
          field_name = self.class.field_mappings[attr_name]
          self[field_name]
        end

        if readonly
          # readonly fields silently ignore sets (airtable rejects them anyway)
          define_method("#{attr_name}=") do |_value|
            nil
          end
        else
          define_method("#{attr_name}=") do |value|
            field_name = self.class.field_mappings[attr_name]
            return if self[field_name] == value

            send("#{attr_name}_will_change!") unless self[field_name] == value
            self[field_name] = value
          end
        end

        # ? method - different behavior for booleans vs other fields
        if field_type == :boolean
          # boolean: returns the actual boolean value
          define_method("#{attr_name}?") do
            field_name = self.class.field_mappings[attr_name]
            !!self[field_name]
          end
        else
          # regular: checks presence
          define_method("#{attr_name}?") do
            field_name = self.class.field_mappings[attr_name]
            value = self[field_name]
            !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
          end
        end
      end
    end

    def attributes = fields

    def attributes=(attrs)
      attrs.each do |key, value|
        if respond_to?("#{key}=")
          send("#{key}=", value)
        else
          self[key.to_s] = value
        end
      end
    end

    def read_attribute(attr_name)
      field_name = self.class.field_mappings[attr_name.to_s] || attr_name.to_s
      self[field_name]
    end

    def write_attribute(attr_name, value)
      field_name = self.class.field_mappings[attr_name.to_s] || attr_name.to_s
      self[field_name] = value
    end

    def attribute_present?(attr_name)
      value = read_attribute(attr_name)
      !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
    end
  end
end
