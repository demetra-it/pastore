# frozen_string_literal: true

module Pastore
  module Params
    # Implements the logic of a single param validation
    class Validation # rubocop:disable Metrics/ClassLength
      attr_reader :value, :errors

      def initialize(name, type, value, modifier = nil, **options) # rubocop:disable Metrics/MethodLength
        @name = name
        @type         = type
        @modifier     = modifier
        @value        = value || options[:default]
        @required     = (options[:required] == true)                           # default: false
        @allow_blank  = (options[:allow_blank].nil? || options[:allow_blank])  # default: true
        @min          = options[:min]
        @max          = options[:max]
        @clamp        = options[:clamp] || [-Float::INFINITY, Float::INFINITY]

        @errors = []

        validate!
      end

      def valid?
        @errors.empty?
      end

      def required?
        @required
      end

      def add_error(error_type, message)
        @errors << { type: 'param', name: @name, value: @value, error: error_type, message: message }
      end

      private

      def validate!
        case @type
        when 'string'  then validate_string!
        when 'number'  then validate_number!
        when 'boolean' then validate_boolean!
        when 'hash'    then validate_hash!
        when 'array'   then validate_array!
        end

        apply_modifier!
      end

      def validate_string!
        # if value is required, check for value presence
        required? && check_if_present!

        # don't go further if value is nil
        return if value.nil?

        # check if value is a string
        check_if_string!

        # check string format
        check_format!
      end

      def validate_number!
        # if value is required, check for value presence
        required? && check_if_present!

        # don't go further if value is nil
        return if value.nil?

        # check if value is a number
        # check if number is between min and max
        # check if value is within specified clamping range, and correct if necessary
        check_if_number! && check_min_max! && check_clamp!
      end

      def validate_boolean!
        # if value is required, check for value presence
        required? && check_if_present!

        return if value.nil?

        # check if value is a boolean
        check_if_boolean!
      end

      def check_if_present!
        if value.nil? || (!@allow_blank && value.to_s.strip == '')
          add_error(:blank, "#{@name} cannot be blank")
          return false
        end

        true
      end

      def check_if_string!
        return true if value.is_a?(String)

        @value = @value.to_s

        true
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

      def check_if_boolean!
        return true if [true, false].any?(value)

        if value.is_a?(String) && boolean?
          @value = %w[t true y yes].any?(value.strip.downcase)
          return true
        end

        add_error(:type, "#{@name} has invalid type: #{@type} expected")

        false
      end

      def check_format!
        return true if @format.nil?

        add_error(:format, "#{@name} has invalid format") if value.match(@format).nil?

        true
      end

      def check_min_max!
        add_error(:min, "#{@name} should be greater than #{@min}") if @min && value < @min
        add_error(:max, "#{@name} should be smaller than #{@max}") if @max && value > @max
      end

      def check_clamp!
        @value = @value.clamp(@clamp.first || -Float::INFINITY, @clamp.last || Float::INFINITY)
      end

      def apply_modifier!
        return if @modifier.nil?

        @value = @modifier.call(@value)
      end

      def numeric?
        !Float(value).nil?
      rescue ArgumentError
        false
      end

      def boolean?
        %w[t true y yes f false n no].any?(value.strip.downcase)
      end
    end
  end
end
