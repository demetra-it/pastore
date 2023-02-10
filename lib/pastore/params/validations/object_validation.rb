# frozen_string_literal: true

module Pastore
  module Params
    # Implements the validation logic for object parameters.
    class ObjectValidation < Validation
      def initialize(name, value, modifier, **options)
        super(name, 'object', value, modifier, **options)
      end

      private

      def validate!
        # check for value presence and if it's allowed to be blank
        check_presence!

        # don't go further if value is blank
        return if value.to_s.strip == ''

        # check if value is a boolean
        return unless check_if_object!

        # check if value is in the list of allowed values
        check_allowed_values!

        # apply the modifier
        apply_modifier!
      end

      def check_if_object!
        return true if [Hash, HashWithIndifferentAccess, ActionController::Parameters].include?(value.class)

        # When value is a string, try to parse it as JSON
        if value.is_a?(String)
          begin
            @value = JSON.parse(value)
            return true
          rescue JSON::ParserError
            # Do nothing
          end
        end

        add_error(:type, "#{@name} has invalid type: #{@type} expected")

        false
      end
    end
  end
end
