# frozen_string_literal: true

module Pastore
  module Params
    # Implements the validation logic for string parameters.
    class StringValidation < Validation
      def initialize(name, value, modifier, **options)
        @format = options[:format]

        super(name, 'string', value, modifier, **options)
      end

      private

      def validate!
        # check for value presence and if it's allowed to be blank
        check_presence!

        # don't go further if value is blank
        return if value.to_s.strip == ''

        # check if value is a string
        return unless check_if_string! && check_format!

        # check if value is in the list of allowed values
        check_allowed_values!

        # apply the modifier
        apply_modifier!
      end

      def check_if_string!
        return true if value.is_a?(String)

        @value = @value.to_s

        true
      end

      # Check if the value matches the specified format
      def check_format!
        return true if @format.nil?

        add_error(:invalid_format, "#{@name} has invalid format") if value.match(@format).nil?

        true
      end
    end
  end
end
