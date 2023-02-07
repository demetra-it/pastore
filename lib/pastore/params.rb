# frozen_string_literal: true

require 'active_support/concern'
require_relative 'params/settings'

module Pastore
  # Implements the features for Rails controller params validation.
  module Params
    class ParamAlreadyDefinedError < StandardError; end

    extend ActiveSupport::Concern

    included do
      before_action do
        pastore_params = self.class.pastore_params
        validation_errors = pastore_params.validate(params, action_name)
        next if validation_errors.empty?

        if pastore_params.invalid_params_cbk.present?
          instance_eval(&guards.invalid_params_cbk)
          response.status = :unprocessable_entity
        else
          render json: { message: 'Unprocessable Entity', errors: validation_errors }, status: :unprocessable_entity
        end
      end
    end

    # Implement Pastore::Params class methods
    module ClassMethods
      attr_accessor :_pastore_params

      def pastore_params
        self._pastore_params ||= Settings.new(superclass)
      end

      def on_invalid_params(&block)
        pastore_params.invalid_params_cbk = block
      end

      def param(name, **options)
        pastore_params.add(name, **options)
      end

      def scope(*keys, &block)
        return unless block_given?

        pastore_params.set_scope(*keys)
        block.call
        pastore_params.reset_scope!
      end

      def method_added(name, *args, &block)
        pastore_params.save_for(name)
        super
      end
    end
  end
end
