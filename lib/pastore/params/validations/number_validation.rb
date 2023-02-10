# frozen_string_literal: true

module Pastore
  module Params
    # Implements the validation logic for number parameters.
    class NumberValidation < Validation
      def initialize(name, value, modifier, **options)
        @min          = options[:min]
        @max          = options[:max]
        @clamp        = options[:clamp] || [-Float::INFINITY, Float::INFINITY]

        super(name, 'number', value, modifier, **options)
      end

      private

      def validate!
        # check for value presence and if it's allowed to be blank
        check_presence!

        # don't go further if value is blank
        return if value.to_s.strip == ''

        # check if value is a number
        # check if number is between min and max
        # check if value is within specified clamping range, and correct if necessary
        return unless check_if_number! && check_min_max! && check_clamp!

        # check if value is in the list of allowed values
        check_allowed_values!

        # apply the modifier
        apply_modifier!
      end

      def check_if_number!
        return true if value.is_a?(Integer) || value.is_a?(Float)

        if value.is_a?(String) && numeric?
          @value = value.to_f
          @value = value.to_i if value.modulo(1).zero?

          return true
        end

        add_error(:type, "#{@name} has invalid type: #{@type} expected")

        false
      end

      def check_min_max!
        min_invalid = @min && value < @min
        max_invalid = @max && value > @max

        add_error(:min, "#{@name} should be greater than #{@min}") if min_invalid
        add_error(:max, "#{@name} should be smaller than #{@max}") if max_invalid

        min_invalid || max_invalid ? false : true
      end

      def check_clamp!
        @value = @value.clamp(@clamp.first || -Float::INFINITY, @clamp.last || Float::INFINITY)
      end
    end
  end
end
