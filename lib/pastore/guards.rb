# frozen_string_literal: true

require 'active_support/concern'

module Pastore
  # Implements the features for Rails controller access guards.
  module Guards # rubocop:disable Metrics/ModuleLength
    extend ActiveSupport::Concern

    included do
      before_action :pastore_check_access
    end

    class_methods do # rubocop:disable Metrics/BlockLength
      attr_accessor :_role_detector, :_default_strategy, :_action_permitted_roles, :_controller_allowed_roles,
                    :_forbidden_callback, :_action_authorization_lambda, :_controller_authorization_lambdas,
                    :_action_denied_roles, :_controller_denied_roles, :_actions_with_skipped_guards,
                    :_actions_with_active_guards

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

      def skip_guards(*actions, except: [])
        self._actions_with_active_guards = [except].flatten.compact.map(&:to_sym)
        self._actions_with_skipped_guards = actions.flatten.compact.map(&:to_sym)
      end

      def actions_with_active_guards
        _actions_with_active_guards || []
      end

      def actions_with_skipped_guards
        _actions_with_skipped_guards || []
      end

      # Specify the list of roles allowed to access the action.
      def permit_role(*roles)
        self._action_permitted_roles = [roles].flatten.compact.uniq.map(&:to_s)
      end

      # Specify the list of roles denied to access the action.
      def deny_role(*roles)
        self._action_denied_roles = [roles].flatten.compact.uniq.map(&:to_s)
      end

      # Specify a custom lambda to be called to authorize the action.
      def authorize_with(method_name = nil, &block)
        custom_lambda = method_name.to_sym if method_name.is_a?(Symbol) || method_name.is_a?(String)
        custom_lambda = block if block_given?

        if custom_lambda.present?
          self._action_authorization_lambda = custom_lambda
        else
          raise ArgumentError, 'A block or a method name must be provided'
        end
      end

      # Save the configurations of the action when the action is defined.
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

    # Returns the current role detected by the role detector logic.
    def pastore_current_role
      self.class._role_detector&.call&.to_s
    end

    # Returns the list of roles allowed to access current action.
    def pastore_allowed_roles
      self.class._controller_allowed_roles&.dig(action_name.to_sym) || []
    end

    # Returns the list of roles denied to access current action.
    def pastore_denied_roles
      self.class._controller_denied_roles&.dig(action_name.to_sym) || []
    end

    # Returns the custom lambda to be called to authorize the action.
    def pastore_authorization_lambda
      self.class._controller_authorization_lambdas&.dig(action_name.to_sym)
    end

    def skip_pastore_guards?
      active_guards = self.class._actions_with_active_guards

      # If current action is listed in `:except` field of `skip_guards`, then we have to run guards (return false).
      return false if active_guards&.include?(action_name.to_sym)

      # If `skip_guards` has specified an `:except` field, then we can skip guards, because current action has
      # implicitely been marked as "to skip guards".
      return true if active_guards.present?

      # If `skip_guards` don't have the any `except` field, just check if current actions is listed in
      # `skip_guards`.
      return true if self.class._actions_with_skipped_guards&.include?(action_name.to_sym)

      # Current action isn't listed in `skip_guards`, so we have to run guards (return false).
      false
    end

    # Performs the access check for current action.
    def pastore_check_access # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
      return if skip_pastore_guards?

      if pastore_authorization_lambda.present?
        authorized = instance_eval(&pastore_authorization_lambda) if pastore_authorization_lambda.is_a?(Proc)
        authorized = send(pastore_authorization_lambda) if pastore_authorization_lambda.is_a?(Symbol)

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
