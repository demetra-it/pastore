# frozen_string_literal: true

module Guards
  class ExamplesController < ActionController::API
    include Pastore::Guards

    def index
      render json: { message: 'Hello world!' }
    end

    permit_role :admin, :user
    def test_permit_role
      render json: { message: 'ok' }
    end

    # authorize_with :custom_authorization
    def test_authorize_with
      render json: { message: 'ok' }
    end

    private

    def custom_authorization
      @custom_authorized || false
    end
  end
end
