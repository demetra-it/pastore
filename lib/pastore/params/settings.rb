# frozen_string_literal: true

require_relative 'action_param'
require_relative 'validation'

module Pastore
  module Params
    # Implements the logic for params settings storage for a controller.
    class Settings
      attr_writer :invalid_params_cbk

      def initialize(superklass)
        @super_params = superklass.pastore_params if superklass.respond_to?(:pastore_params)
        reset!
      end

      def reset!
        @actions = {}
        @invalid_params_cbk = nil

        reset_buffer!
        reset_scope!
      end

      def invalid_params_cbk
        @invalid_params_cbk || @super_params&.invalid_params_cbk
      end

      def reset_buffer!
        @buffer = []
      end

      def set_scope(*keys)
        @scope = [keys].flatten.compact.map(&:to_sym)
      end

      def reset_scope!
        @scope = nil
      end

      def add(name, **options)
        options = { scope: @scope }.merge(options.symbolize_keys)

        raise ParamAlreadyDefinedError, "Param #{name} already defined" if @buffer.any? { |p| p.name == name }

        if @scope.present? && options[:scope].present? && @scope != options[:scope]
          error = "Scope overwrite attempt detected (current_scope: #{@scope}, param_scope: #{options[:scope]}) for param #{name}"
          raise ScopeConflictError, error
        end

        param = ActionParam.new(name, **options)

        @buffer << param
      end

      def save_for(action_name)
        @actions[action_name.to_sym] = @buffer
        reset_buffer!
      end

      def validate(params, action_name)
        action_params = @actions[action_name.to_sym]
        return {} if action_params.blank?

        action_params.each_with_object({}) do |validator, errors|
          value = safe_dig(params, *validator.scope, validator.name)
          validation = validator.validate(value)

          if validation.valid?
            update_param_value!(params, validator, validation)

            next if validation.errors.empty?
          end

          errors[validator.name_with_scope] = validation.errors
        end
      end

      private

      def update_param_value!(params, validator, validation)
        if validator.scope.empty?
          params[validator.name] = validation.value
          return
        end

        # Try to create missing scope keys
        key_path = []
        validator.scope.each do |key|
          params[key] ||= {}
          key_path << key

          if params[key].is_a?(ActionController::Parameters)
            params = params[key]
            next
          end

          # if for some reason the scope key is not a hash, we need to add the error to validation errors
          return validation.add_error(:bad_schema, "Invalid param schema at #{key_path.join(".").inspect}")
        end

        params[validator.name] = validation.value
      end

      def safe_dig(params, *keys)
        [keys].flatten.reduce(params) do |acc, key|
          acc.respond_to?(:key?) ? acc[key] : nil
        end
      end
    end
  end
end
