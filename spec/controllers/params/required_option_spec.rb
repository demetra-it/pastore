# frozen_string_literal: true

module Params
  class RequiredParamsTestController < ActionController::API
    include Pastore::Params
  end
end

# rubocop:disable Metrics/BlockLength
RSpec.describe Params::RequiredParamsTestController, type: :controller do
  subject { described_class }

  include_context 'controller for params specs'

  describe 'required params' do
    let(:allow_blank) { true }
    let(:params) { { name: 'John', age: 25 } }

    let(:params_block) do
      lambda do
        subject.param :name, type: 'string', required: true, allow_blank: allow_blank
        subject.param :age, type: 'integer', required: true, allow_blank: allow_blank
      end
    end

    it 'should return a 422 status code if a required param is missing' do
      response = get(action_name)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'should return a 200 status code if all required params are present' do
      response = get(action_name, params: params)
      expect(response).to have_http_status(:ok)
    end

    it 'should not alter the params' do
      get(action_name, params: params)
      expect(controller.params[:name]).to eq(params[:name])
      expect(controller.params[:age]).to eq(params[:age])
    end

    context 'when :allow_blank is true' do
      let(:allow_blank) { true }

      it 'blank string should be considered as present' do
        params[:name] = ''
        response = get(action_name, params: params)
        expect(response).to have_http_status(:ok)
      end

      it 'nil value for string should be considered as present' do
        params[:name] = nil
        response = get(action_name, params: params)
        expect(response).to have_http_status(:ok)
      end

      it 'nil value for integer should be considered as present' do
        params[:age] = nil
        response = get(action_name, params: params)
        expect(response).to have_http_status(:ok)
      end

      it 'missing string param should be considered as missing' do
        params.delete :name
        response = get(action_name, params: params)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'missing integer param should be considered as missing' do
        params.delete :age
        response = get(action_name, params: params)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when :allow_blank is false' do
      let(:allow_blank) { false }

      it 'blank string should be considered as missing' do
        params[:name] = ''
        response = get(action_name, params: params)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'nil should be considered as missing' do
        params[:name] = nil
        response = get(action_name, params: params)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'nil value for integer should be considered as missing' do
        params[:age] = nil
        response = get(action_name, params: params)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
