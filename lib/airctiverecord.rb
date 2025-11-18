# frozen_string_literal: true

require_relative "airctiverecord/version"
require "norairrecord"
require "active_model"
require "airrel"

module AirctiveRecord
  class Error < StandardError; end
  class RecordInvalid < Error; end
  class RecordNotSaved < Error; end

  autoload :Base, "airctiverecord/base"
  autoload :Callbacks, "airctiverecord/callbacks"
  autoload :Validations, "airctiverecord/validations"
  autoload :AttributeMethods, "airctiverecord/attribute_methods"
  autoload :Associations, "airctiverecord/associations"
  autoload :Scoping, "airctiverecord/scoping"
  autoload :Relation, "airctiverecord/relation"
end
