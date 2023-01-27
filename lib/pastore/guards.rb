# frozen_string_literal: true

require 'active_support/concern'

module Pastore
  # Implements the features for Rails controller access guards.
  module Guards
    extend ActiveSupport::Concern

    included do
      before_action :check_access
    end

    class_methods do
      attr_accessor :_role_detector, :_default_strategy, :_action_permitted_roles, :_controller_allowed_roles, :_forbidden_callback

      def detect_role(&block)
        self._role_detector = block
      end

      def forbidden(&block)
        self._forbidden_callback = block
      end

      def use_deny_strategy!
        self._default_strategy = :deny
      end

      def use_allow_strategy!
        self._default_strategy = :allow
      end

      def pastore_default_strategy
        _default_strategy || :deny
      end

      def permit_role(*roles)
        self._action_permitted_roles = [[_action_permitted_roles] + roles].flatten.compact.uniq
      end

      def method_added(name, *args)
        return super if _action_permitted_roles.blank?

        self._controller_allowed_roles ||= {}
        self._controller_allowed_roles[name] = _action_permitted_roles
        self._action_permitted_roles = nil

        super
      end
    end

    protected

    def pastore_current_role
      self.class._role_detector&.call
    end

    def pastore_allowed_roles
      self.class._controller_allowed_roles&.dig(action_name.to_s) || []
    end

    def check_access
      case self.class.pastore_default_strategy
      when :deny then check_access_with_deny_strategy
      when :allow then check_access_with_allow_strategy
      end
    end

    def check_access_with_deny_strategy
      return pastore_deny_access! unless pastore_allowed_roles.include?(pastore_current_role)
    end

    def pastore_deny_access!
      callback = self.class._forbidden_callback

      if callback
        instance_eval(&callback)
        response.status = :forbidden
      else
        render json: { message: 'Forbidden' }, status: :forbidden
      end
    end
  end
end
