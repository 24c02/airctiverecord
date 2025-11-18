# frozen_string_literal: true

module AirctiveRecord
  module Associations
    extend ActiveSupport::Concern

    class_methods do
      # just add activerecord-style defaults, norairrecord does the heavy lifting
      def has_many(name, options_arg = nil, **options_kwargs)
        options = options_arg || options_kwargs

        if options[:through]
          define_has_many_through(name, options)
        else
          column = options[:column] || options[:foreign_key] || "#{name.to_s.singularize}_ids"
          klass = options[:class_name] || name.to_s.classify

          super(name, { column: column, class: klass }.merge(options))
        end
      end

      def belongs_to(name, **options)
        column = options[:column] || options[:foreign_key] || "#{name}_id"
        klass = options[:class_name] || name.to_s.classify

        super(name, { column: column, class: klass }.merge(options))
      end

      def has_one(name, **options)
        column = options[:column] || options[:foreign_key] || "#{name}_id"
        klass = options[:class_name] || name.to_s.classify

        super(name, { column: column, class: klass }.merge(options))
      end

      private

      def define_has_many_through(name, options)
        through = options[:through]
        source = options[:source] || name.to_s.singularize

        define_method(name) do
          send(through).flat_map { |record| Array(record.send(source)) }.compact
        end
      end
    end
  end
end
