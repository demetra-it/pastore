# frozen_string_literal: true

module Pastore
  module Params
    # Implements the validation logic for object parameters.
    class BooleanValidation < Validation
      def initialize(name, value, modifier, **options)
        super(name, 'boolean', value, modifier, **options)
      end

      private

      def validate!
        # check for value presence and if it's allowed to be blank
        check_presence!

        # don't go further if value is blank
        return if value.to_s.strip == ''

        # check if value is a boolean
        return unless check_if_boolean!

        # check if value is in the list of allowed values
        check_allowed_values!

        # apply the modifier
        apply_modifier!
      end

      def check_if_boolean!
        return true if [true, false].any?(value)

        if value.is_a?(String) && boolean?
          @value = %w[t true y yes].any?(value.strip.downcase)
          return true
        end

        add_error(:type, "#{@name} has invalid type: #{@type} expected")

        false
      end

      def boolean?
        %w[t true y yes f false n no].any?(value.strip.downcase)
      end
    end
  end
end
