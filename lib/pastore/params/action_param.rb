# frozen_string_literal: true

module Pastore
  module Params
    # Stores data about action parameters
    class ActionParam
      AVAILABLE_TYPES = %w[string number boolean date object array any].freeze
      TYPE_ALIASES = {
        'text' => 'string',
        'integer' => 'number',
        'float' => 'number',
        'hash' => 'object'
      }.freeze

      attr_reader :name, :type, :modifier, :options, :scope

      def initialize(name, **options)
        @name = name
        @options = options
        @scope = [@options&.fetch(:scope, nil)].flatten.compact
        @array = @options&.fetch(:array, false) == true
        @modifier = @options&.fetch(:modifier, nil)
        @type = @options&.fetch(:type, :any)

        check_options!
      end

      def validate(value)
        Pastore::Params::Validation.validate!(name, type, value, modifier, **options)
      end

      def array?
        @array
      end

      def name_with_scope
        [@scope, name].flatten.compact.join('.')
      end

      private

      def check_options!
        check_type!
        check_modifier!
        check_required!
        check_default!
        check_min_max!
        check_format!
        check_clamp!
      end

      def check_type!
        @type = @type.to_s.strip.downcase

        @type = TYPE_ALIASES[@type] unless TYPE_ALIASES[@type].nil?

        valid_type = AVAILABLE_TYPES.include?(@type)
        raise Pastore::Params::InvalidParamTypeError, "Invalid param type: #{@type.inspect}" unless valid_type
      end

      def check_modifier!
        return if @modifier.nil? || @modifier.is_a?(Proc)

        raise "Invalid modifier, lambda or Proc expected, got #{@modifier.class}"
      end

      def check_required!
        options[:required] = (options[:required] == true)
      end

      def check_default!
        return if options[:default].nil?

        validation = Pastore::Params::Validation.validate!(name, type, options[:default], modifier, **options)
        return if validation.valid?

        raise Pastore::Params::InvalidValueError, "Invalid default value: #{validation.errors.join(",")}"
      end

      def check_min_max!
        check_min!
        check_max!

        return if options[:min].nil? || options[:max].nil?

        raise 'Invalid min-max range' unless options[:min] <= options[:max]
      end

      def check_min!
        min = options[:min]
        return if min.nil?

        raise 'Invalid minimum' unless min.is_a?(Integer) || min.is_a?(Float)
      end

      def check_max!
        max = options[:max]
        return if max.nil?

        raise 'Invalid maximum' unless max.is_a?(Integer) || max.is_a?(Float)
      end

      def check_format!
        return if options[:format].nil?

        raise 'Invalid format' unless options[:format].is_a?(Regexp)
      end

      def check_clamp!
        return if options[:clamp].nil?

        raise 'Invalid clamp' unless options[:clamp].is_a?(Array) || options[:clamp].is_a?(Range)
        raise 'Invalid clamp range' unless (options[:clamp].first <=> options[:clamp].last) <= 0
      end
    end
  end
end
