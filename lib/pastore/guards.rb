# frozen_string_literal: true

require 'active_support/concern'
require_relative 'guards/settings'

module Pastore
  # Implements the features for Rails controller access guards.
  module Guards
    extend ActiveSupport::Concern

    class RoleConflictError < StandardError; end

    included do
      before_action do
        guards = self.class.pastore_guards
        next if guards.access_granted?(self, action_name)

        if guards.forbidden_cbk.present?
          instance_eval(&guards.forbidden_cbk)
          response.status = :forbidden
        else
          render json: { message: 'Forbidden' }, status: :forbidden
        end
      end
    end

    class_methods do # rubocop:disable Metrics/BlockLength
      attr_accessor :_pastore_guards

      def pastore_guards
        self._pastore_guards ||= Pastore::Guards::Settings.new(superclass)
      end

      # Sets the logic to use for current role detection.
      def detect_role(&block)
        pastore_guards.role_detector = block
      end

      # Specifies a custom callback to be called when access is forbidden.
      def forbidden(&block)
        pastore_guards.forbidden_cbk = block
      end

      # Sets the default strategy to "deny".
      def use_deny_strategy!
        pastore_guards.use_deny_strategy!
      end

      # Sets the default strategy to "allow".
      def use_allow_strategy!
        pastore_guards.use_allow_strategy!
      end

      def skip_guards(*actions, except: [])
        pastore_guards.skip_guards_for(*actions)
        pastore_guards.force_guards_for(*except)
      end

      # Specify the list of roles allowed to access the action.
      def permit_role(*roles)
        pastore_guards.permit_role(*roles)
      end

      # Specify the list of roles denied to access the action.
      def deny_role(*roles)
        pastore_guards.deny_role(*roles)
      end

      # Specify a custom lambda to be called to authorize the action.
      def authorize_with(method_name = nil, &block)
        pastore_guards.authorize_with(method_name, &block)
      end

      # Save the configurations of the action when the action is defined.
      def method_added(name, *args)
        pastore_guards.save_guards_for(name)
        super
      end
    end
  end
end
