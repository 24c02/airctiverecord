# frozen_string_literal: true

module AirctiveRecord
  class Base < Norairrecord::Table
    extend ActiveModel::Naming
    extend ActiveModel::Translation
    include ActiveModel::Conversion
    include ActiveModel::Dirty
    include AirctiveRecord::Validations
    include AirctiveRecord::Callbacks
    include AirctiveRecord::AttributeMethods
    include AirctiveRecord::Associations
    include AirctiveRecord::Scoping

    class << self
      def column_names
        @column_names ||= []
      end

      def attribute(name, airtable_field_name = nil, **options)
        column_names << name.to_s unless column_names.include?(name.to_s)
        field(name, airtable_field_name, **options)
      end

      # each model gets its own Relation class
      def relation_class
        @relation_class ||= Class.new(AirctiveRecord::Relation)
      end

      def relation_class_name = "#{name}::Relation"
    end

    def initialize(attributes = {}, **kwargs)
      # Extract id and created_at if present
      id = kwargs.delete(:id)
      created_at = kwargs.delete(:created_at)

      # Merge positional hash and kwargs to handle both styles
      all_attrs = attributes.is_a?(Hash) ? attributes.merge(kwargs) : kwargs

      # Norairrecord::Table expects field names as STRING keys
      # We need to convert Ruby attribute names to Airtable field names
      mapped_attrs = {}
      all_attrs.each do |key, value|
        field_name = self.class.field_mappings[key.to_s] || key.to_s
        mapped_attrs[field_name.to_s] = value # Ensure string keys
      end

      # Call norairrecord's initialize properly
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.0.0")
        if mapped_attrs.empty?
          super(id: id, created_at: created_at)
        else
          super(mapped_attrs, id: id, created_at: created_at)
        end
      else
        super(mapped_attrs, id: id, created_at: created_at)
      end

      clear_changes_information
    end

    def assign_attributes(attrs)
      self.attributes = attrs
    end

    def serializable_fields
      # exclude readonly fields from serialization
      fields.reject { |k, _v| self.class.readonly_fields.include?(k) }
    end

    def save(**options)
      return false unless valid?

      begin
        run_callbacks :save do
          if new_record?
            run_callbacks :create do
              super(**options)
            end
          else
            run_callbacks :update do
              super(**options)
            end
          end
        end
        changes_applied
        true
      rescue StandardError
        false
      end
    end

    def save!(**options)
      raise RecordInvalid, errors.full_messages.join(", ") unless valid?

      save(**options) || raise(RecordNotSaved, "Failed to save record")
    end

    def update(attributes)
      attributes.each { |key, value| send("#{key}=", value) }
      save
    end

    def update!(attributes)
      attributes.each { |key, value| send("#{key}=", value) }
      save!
    end

    def reload
      return self if new_record?

      reloaded = self.class.find(id)
      @fields = reloaded.fields
      @created_at = reloaded.created_at
      clear_changes_information
      self
    end

    def persisted? = !new_record?

    def to_param = id

    def to_key = persisted? ? [id] : nil

    def to_model = self
  end
end
