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
      end

      def invalid_params_cbk
        @invalid_params_cbk || @super_params&.invalid_params_cbk
      end

      def reset_buffer!
        @buffer = []
      end

      def add(name, **options)
        param = ActionParam.new(name, **options)
        raise ParamAlreadyDefinedError, "Param #{name} already defined" if @buffer.any? { |p| p.name == name }

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
          param_name = validator.name
          validation = validator.validate(params[param_name])

          if validation.valid?
            params[param_name] = validation.value
            next
          end

          errors[param_name] = validation.errors
        end
      end
    end
  end
end
