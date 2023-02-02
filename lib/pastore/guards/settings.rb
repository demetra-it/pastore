# frozen_string_literal: true

module Pastore
  module Guards
    # Implements a structure where to store the settings for the guards.
    class Settings # rubocop:disable Metrics/ClassLength

      attr_writer :role_detector, :forbidden_cbk
      attr_reader :strategy

      def initialize(superklass)
        @super_guards = superklass.pastore_guards if superklass.respond_to?(:pastore_guards)
        @superclass = superklass
        reset!
      end

      def reset!
        @strategy = :deny
        @role_detector = nil
        @forbidden_cbk = nil
        @actions = {}
        @buffer = {}
        @skipped_guards = []
        @forced_guards = []
      end

      def role_detector
        @role_detector || @super_guards&.role_detector
      end

      def forbidden_cbk
        @forbidden_cbk || @super_guards&.forbidden_cbk
      end

      def use_allow_strategy!
        @strategy = :allow
      end

      def use_deny_strategy!
        @strategy = :deny
      end

      def permit_role(*roles)
        new_roles = [roles].flatten.compact.uniq.map(&:to_s)
        conflicts = @buffer.fetch(:denied_roles, []) & new_roles

        unless conflicts.empty?
          raise Pastore::Guards::RoleConflictError, "Roles conflict: #{conflicts} roles already specified with #deny_role"
        end

        if @buffer[:authorization_lambda].present?
          raise Pastore::Guards::RoleConflictError, 'An #authorize_with has already been specified'
        end

        @buffer[:permitted_roles] = new_roles
      end

      def deny_role(*roles)
        new_roles = [roles].flatten.compact.uniq.map(&:to_s)
        conflicts = @buffer.fetch(:permitted_roles, []) & new_roles

        unless conflicts.empty?
          raise Pastore::Guards::RoleConflictError, "Roles conflict: #{conflicts} roles already specified with #permit_role"
        end

        if @buffer[:authorization_lambda].present?
          raise Pastore::Guards::RoleConflictError, 'An #authorize_with has already been specified'
        end

        @buffer[:denied_roles] = new_roles
      end

      def authorize_with(method_name = nil, &block)
        if @buffer[:permitted_roles].present? || @buffer[:denied_roles].present?
          raise Pastore::Guards::RoleConflictError, 'A role has already been specified with #permit_role or #deny_role'
        end

        custom_lambda = method_name.to_sym if method_name.is_a?(Symbol) || method_name.is_a?(String)
        custom_lambda = block if block_given?

        if custom_lambda.present?
          @buffer[:authorization_lambda] = custom_lambda
        else
          raise ArgumentError, 'A block or a method name must be provided'
        end
      end

      def save_guards_for(action_name)
        return if @buffer.empty?

        name = action_name.to_sym
        @actions[name] ||= {}

        save_permitted_roles!(name)
        save_denied_roles!(name)
        save_authorization_lambda!(name)

        reset_buffer!
      end

      def reset_buffer!
        @buffer = {}
      end

      def skip_guards_for(*actions)
        @skipped_guards = [actions].flatten.compact.map(&:to_sym)
      end

      def force_guards_for(*actions)
        @forced_guards = [actions].flatten.compact.map(&:to_sym)
      end

      # Returns the current role for the controller.
      def current_role(controller)
        return nil if role_detector.blank?

        controller.instance_exec(&role_detector)&.to_s
      end

      def access_granted?(controller, action_name) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        # Get setting for the current action.
        action = @actions[action_name.to_sym]

        return true if skip_guards?(action_name)

        result = authorize_with_lambda(controller, action)
        return result unless result.nil?

        role = current_role(controller)

        return false if action&.dig(:denied_roles)&.include?(role)

        @strategy == :allow || (@strategy == :deny && action&.dig(:permitted_roles)&.include?(role)) || false
      end

      private

      def save_permitted_roles!(action_name)
        return if @buffer[:permitted_roles].blank?

        @actions[action_name][:permitted_roles] = @buffer[:permitted_roles]
      end

      def save_denied_roles!(action_name)
        return if @buffer[:denied_roles].blank?

        @actions[action_name][:denied_roles] = @buffer[:denied_roles]
      end

      def save_authorization_lambda!(action_name)
        return if @buffer[:authorization_lambda].blank?

        @actions[action_name][:authorization_lambda] = @buffer[:authorization_lambda]
      end

      def skip_guards?(action_name)
        # If current action is listed in `:except` field of `skip_guards`, then we have to run guards (return false).
        return false if @forced_guards&.include?(action_name.to_sym)

        # If `skip_guards` has specified an `:except` field, then we can skip guards, because current action has
        # implicitely been marked as "to skip guards".
        return true if @forced_guards.present?

        # If `skip_guards` don't have the any `except` field, just check if current actions is listed in
        # `skip_guards`.
        return true if @skipped_guards&.include?(action_name.to_sym)

        # Current action isn't listed in `skip_guards`, so we have to run guards (return false).
        false
      end

      def authorize_with_lambda(controller, action)
        # When an authorization lambda is defined, it has the priority over the other guards.
        authorization_lambda = action&.dig(:authorization_lambda)
        if authorization_lambda.present?
          result = controller.instance_eval(&authorization_lambda) if authorization_lambda.is_a?(Proc)
          result = controller.instance_eval(authorization_lambda.to_s) if authorization_lambda.is_a?(Symbol)

          return result
        end

        nil
      end
    end
  end
end
