# frozen_string_literal: true

module AirctiveRecord
  module Validations
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Validations

      define_model_callbacks :validation
    end

    def valid?(context = nil)
      run_callbacks :validation do
        super
      end
    end

    def save(**options)
      return false unless valid?
      super
    end
  end
end
