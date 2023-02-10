# frozen_string_literal: true

module Pastore
  module Params
    # Implements the logic of a single param validation
    class Validation
      require_relative 'validations/string_validation'
      require_relative 'validations/number_validation'
      require_relative 'validations/boolean_validation'
      require_relative 'validations/object_validation'
      require_relative 'validations/date_validation'

      # Validates the value based on the given type and values with the appropriate validator.
      def self.validate!(name, type, value, modifier = nil, **options)
        case type
        when 'string'  then Pastore::Params::StringValidation.new(name, value, modifier, **options)
        when 'number'  then Pastore::Params::NumberValidation.new(name, value, modifier, **options)
        when 'boolean' then Pastore::Params::BooleanValidation.new(name, value, modifier, **options)
        when 'object'  then Pastore::Params::ObjectValidation.new(name, value, modifier, **options)
        when 'date'    then Pastore::Params::DateValidation.new(name, value, modifier, **options)
        when 'any'     then Validation.new(name, 'any', value, modifier, **options)
        else
          raise Pastore::Params::InvalidValidationTypeError, "Invalid validation type: #{type}"
        end
      end

      attr_reader :value, :errors

      def initialize(name, type, value, modifier = nil, **options)
        @name = name
        @type         = type
        @modifier     = modifier
        @value        = value.nil? ? options[:default] : value
        @required     = (options[:required] == true)                           # default: false
        @allow_blank  = (options[:allow_blank].nil? || options[:allow_blank])  # default: true

        @errors = []

        validate!
      end

      # Returns true if the value is valid, false otherwise.
      def valid?
        @errors.empty?
      end

      # Returns true if the value is required, false otherwise.
      def required?
        @required
      end

      # Adds an error to the list of errors.
      def add_error(error_type, message)
        @errors << { type: 'param', name: @name, value: @value, error: error_type, message: message }
      end

      private

      # Performs a basic validation of the value and applies the modifier.
      def validate!
        # check for value presence and if it's allowed to be blank
        check_presence!
        apply_modifier!
      end

      # Checks if the value is present (not nil) and if it's allowed to be blank.
      def check_presence!
        valid = true

        # required options ensures that value is present (not nil)
        valid = false if required? && value.nil?

        # allow_blank option ensures that value is not blank (not empty)
        valid = false if !@allow_blank && value.to_s.strip == ''

        add_error(:blank, "#{@name} cannot be blank") unless valid

        valid
      end

      # Applies the modifier to the value.
      def apply_modifier!
        return if @modifier.nil?

        @value = @modifier.call(@value)
      end

      # check if value is in the list of allowed values
      def check_allowed_values!
        return if @allowed_values.nil?
        return if @allowed_values.include?(value)

        add_error(:allowed_values, "#{@name} has invalid value: #{value}")
      end

      # check if value is a number
      def numeric?
        !Float(value).nil?
      rescue ArgumentError
        false
      end
    end
  end
end
