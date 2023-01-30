# frozen_string_literal: true

module Guards
  class ExamplesController < ActionController::API
    include Pastore::Guards

    def index
      render json: { message: 'Hello world!' }
    end

    permit_role :admin, :user, :guest
    def test_permit_role
      render json: { message: 'ok' }
    end

    permit_role :admin
    def test_unpermitted_role
      render json: { message: 'ok' }
    end

    deny_role :admin
    def test_denied_role
      render json: { message: 'ok' }
    end

    authorize_with { true }
    def test_authorized_with_permitted
      render json: { message: 'ok' }
    end

    authorize_with { false }
    def test_authorized_with_denied
      render json: { message: 'ok' }
    end

    authorize_with :custom_authorization
    def test_authorized_with_method
      render json: { message: 'ok' }
    end

    authorize_with { false }
    permit_role :admin
    def test_authorization_priority
      render json: { message: 'ok' }
    end

    authorize_with { true }
    deny_role :admin
    def test_authorization_priority2
      render json: { message: 'ok' }
    end

    permit_role :admin, :user
    permit_role :guest
    def test_cumulative_permit_role
      render json: { message: 'ok' }
    end

    deny_role :admin, :user
    deny_role :guest
    def test_cumulative_deny_role
      render json: { message: 'ok' }
    end

    private

    def custom_authorization
      false
    end
  end
end
