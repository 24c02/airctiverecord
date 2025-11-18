# frozen_string_literal: true

module AirctiveRecord
  # Base Relation class - models create subclasses of this
  # Each model's relation knows about that model's field mappings and scopes
  class Relation < Airrel::Relation
    # override where to apply field mappings when building formulas from hashes
    def where(conditions)
      if conditions.is_a?(Hash)
        # build formula with field mappings
        formula = Airrel::FormulaBuilder.hash_to_formula(conditions, klass.field_mappings)
        super(formula)
      else
        super
      end
    end

    # override to use field mappings when building airtable params
    def to_airtable_params
      params = {}

      # filter
      params[:filter] = @where_clause.to_airtable_formula if @where_clause.any?

      # sort - use field mappings
      if @order_values.any?
        params[:sort] = @order_values.map do |field, direction|
          mapped_field = klass.field_mappings[field.to_s] || field.to_s
          { field: mapped_field, direction: direction.to_s }
        end
      end

      # limit
      params[:max_records] = @limit_value if @limit_value

      # offset
      params[:offset] = @offset_value if @offset_value

      params
    end

    # spawn returns a new instance of the same Relation subclass
    def spawn
      self.class.new(klass).tap do |relation|
        relation.instance_variable_set(:@where_clause, @where_clause)
        relation.instance_variable_set(:@order_values, @order_values.dup)
        relation.instance_variable_set(:@limit_value, @limit_value)
        relation.instance_variable_set(:@offset_value, @offset_value)
      end
    end
  end
end
