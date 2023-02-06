# frozen_string_literal: true

module Params
  class ExamplesController < ActionController::API
    include Pastore::Params

    def index
      render json: { message: 'ok' }
    end

    param :name, type: 'string', required: true
    def test_required
      render json: { message: 'ok' }
    end
  end
end
