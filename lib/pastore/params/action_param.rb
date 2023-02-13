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

        check_clamp_type!
        convert_clamp_to_array!
        normalize_datetime_clamp!
        check_clamp_bounds!
      end

      def check_clamp_type!
        return if options[:clamp].nil?
        return if [Array, Range].include?(options[:clamp].class)

        raise Pastore::Params::InvalidValueError, "Invalid clamp value: #{options[:clamp].inspect}"
      end

      def convert_clamp_to_array!
        clamp = options[:clamp]

        options[:clamp] = clamp.is_a?(Array) ? [clamp.first, clamp.last] : [clamp.begin, clamp.end]
      end

      def check_clamp_bounds!
        clamp = options[:clamp]
        return if clamp.first.nil? || clamp.last.nil?

        raise Pastore::Params::InvalidValueError, "Invalid clamp range: #{clamp.inspect}" if clamp.first > clamp.last
      end

      def normalize_datetime_clamp!
        return unless @type == 'date'

        options[:clamp] = options[:clamp].map do |d|
          return d if d.nil?

          case d
          when Date then d
          when String then DateTime.parse(d.to_s)
          when Integer, Float then Time.at(d).to_datetime
          when Time then d.to_datetime
          else
            raise Pastore::Params::InvalidValueError, "Invalid clamp value: #{options[:clamp].inspect}"
          end
        end
      rescue Date::Error
        raise Pastore::Params::InvalidValueError, "Invalid clamp value: #{options[:clamp].inspect}"
      end
    end
  end
end
