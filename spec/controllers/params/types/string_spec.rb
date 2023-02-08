# frozen_string_literal: true

module Params
  class StringParamsTestController < ActionController::API
    include Pastore::Params
  end
end

RSpec.describe Params::StringParamsTestController, type: :controller do
  subject { described_class }

  include_context 'controller for params specs'

  context 'when type is :string' do
    let(:params) { { string: 'John', numeric: 25, object: { a: 1, b: 2 }, boolean: true } }
    let(:params_block) do
      lambda do
        subject.param :string, type: 'string'
      end
    end

    it 'should be ok when param value is a string' do
      response = get(action_name, params: { string: 'John' })
      expect(response).to have_http_status(:ok)
    end

    it 'should be ok when param value is an integer, float or a object' do
      response = get(action_name, params: { string: 25 })
      expect(response).to have_http_status(:ok)

      response = get(action_name, params: { string: 25.5 })
      expect(response).to have_http_status(:ok)

      response = get(action_name, params: { string: { a: 1, b: 2 } })
      expect(response).to have_http_status(:ok)
    end
  end
end
