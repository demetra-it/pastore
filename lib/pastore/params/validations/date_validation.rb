# frozen_string_literal: true

module Pastore
  module Params
    # Implements the validation logic for date parameters.
    class DateValidation < Validation
      def initialize(name, value, modifier, **options)
        @min = options[:min]
        @max = options[:max]
        @clamp = options[:clamp]

        super(name, 'date', value, modifier, **options)
      end

      private

      def validate!
        # check for value presence and if it's allowed to be blank
        check_presence!

        # don't go further if value is blank
        return if value.to_s.strip == ''

        # check if value is a boolean
        return unless check_if_date! && check_min_max! && check_clamp!

        # check if value is in the list of allowed values
        check_allowed_values!

        # apply the modifier
        apply_modifier!
      end

      def check_if_date!
        return true if [Date, Time, DateTime].include?(value.class)

        if numeric?
          @value = Time.at(value.to_f).to_datetime
          return true
        end

        # When value is a string, try to parse it as a DateTime object
        if value.is_a?(String)
          begin
            @value = DateTime.parse(value)
            return true
          rescue Date::Error
            # Do nothing
          end
        end

        add_error(:invalid_type, "#{@name} has invalid type: #{@type} expected")

        false
      end

      def check_min_max!
        min_invalid = @min && value < @min
        max_invalid = @max && value > @max

        add_error(:too_small, "#{@name} should be greater than #{@min}") if min_invalid
        add_error(:too_large, "#{@name} should be smaller than #{@max}") if max_invalid

        min_invalid || max_invalid ? false : true
      end

      def check_clamp!
        return true if @clamp.nil?

        @value = @value.clamp(@clamp.first, @clamp.last)
      end
    end
  end
end
