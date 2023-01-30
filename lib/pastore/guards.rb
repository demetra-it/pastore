# frozen_string_literal: true

require 'active_support/concern'

module Pastore
  # Implements the features for Rails controller access guards.
  module Guards
    extend ActiveSupport::Concern

    included do
      before_action :pastore_check_access
    end

    class_methods do # rubocop:disable Metrics/BlockLength
      attr_accessor :_role_detector, :_default_strategy, :_action_permitted_roles, :_controller_allowed_roles,
                    :_forbidden_callback, :_action_authorization_lambda, :_controller_authorization_lambdas,
                    :_action_denied_roles, :_controller_denied_roles

      # Sets the logic to use for current role detection.
      def detect_role(&block)
        self._role_detector = block
      end

      # Specifies a custom callback to be called when access is forbidden.
      def forbidden(&block)
        self._forbidden_callback = block
      end

      # Sets the default strategy to "deny".
      def use_deny_strategy!
        self._default_strategy = :deny
      end

      # Sets the default strategy to "allow".
      def use_allow_strategy!
        self._default_strategy = :allow
      end

      # Returns the default strategy.
      def pastore_default_strategy
        _default_strategy || :deny
      end

      def permit_role(*roles)
        self._action_permitted_roles = [[_action_permitted_roles] + roles].flatten.compact.uniq.map(&:to_s)
      end

      def deny_role(*roles)
        self._action_denied_roles = [[_action_denied_roles] + roles].flatten.compact.uniq.map(&:to_s)
      end

      def authorize_with(method_name = nil, &block)
        custom_lambda = method_name.to_sym if method_name.is_a?(Symbol) || method_name.is_a?(String)
        custom_lambda = block if block_given?

        if custom_lambda.present?
          self._action_authorization_lambda = custom_lambda
        else
          raise ArgumentError, 'A block or a method name must be provided'
        end
      end

      def method_added(name, *args) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        unless _action_permitted_roles.blank?
          self._controller_allowed_roles ||= {}
          self._controller_allowed_roles[name] = _action_permitted_roles
          self._action_permitted_roles = nil
        end

        unless _action_denied_roles.blank?
          self._controller_denied_roles ||= {}
          self._controller_denied_roles[name] = _action_denied_roles
          self._action_denied_roles = nil
        end

        unless _action_authorization_lambda.blank?
          self._controller_authorization_lambdas ||= {}
          self._controller_authorization_lambdas[name] = _action_authorization_lambda
          self._action_authorization_lambda = nil
        end

        super
      end
    end

    protected

    def pastore_current_role
      self.class._role_detector&.call&.to_s
    end

    def pastore_allowed_roles
      self.class._controller_allowed_roles&.dig(action_name.to_sym) || []
    end

    def pastore_denied_roles
      self.class._controller_denied_roles&.dig(action_name.to_sym) || []
    end

    def authorization_lambda
      self.class._controller_authorization_lambdas&.dig(action_name.to_sym)
    end

    def pastore_check_access
      if authorization_lambda.present?
        authorized = instance_eval(&authorization_lambda) if authorization_lambda.is_a?(Proc)
        authorized = send(authorization_lambda) if authorization_lambda.is_a?(Symbol)

        return if authorized

        return pastore_deny_access!
      end

      case self.class.pastore_default_strategy
      when :deny then check_access_with_deny_strategy
      when :allow then check_access_with_allow_strategy
      end
    end

    def check_access_with_deny_strategy
      return pastore_deny_access! unless pastore_allowed_roles.include?(pastore_current_role)
    end

    def check_access_with_allow_strategy
      return pastore_deny_access! if pastore_denied_roles.include?(pastore_current_role)
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
