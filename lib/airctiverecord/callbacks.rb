# frozen_string_literal: true

module AirctiveRecord
  module Callbacks
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Validations::Callbacks

      define_model_callbacks :save, :create, :update, :destroy
      define_model_callbacks :initialize, only: :after
    end

    def destroy
      run_callbacks :destroy do
        super
      end
    end
  end
end
