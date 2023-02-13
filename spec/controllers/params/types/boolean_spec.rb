# frozen_string_literal: true

module Params
  class BooleanParamsTestController < ActionController::API
    include Pastore::Params
  end
end

# rubocop:disable Metrics/BlockLength
RSpec.describe Params::BooleanParamsTestController, type: :controller do
  subject { described_class }
  include_context 'controller for params specs'

  context 'when type is :boolean' do
    let(:required) { nil }
    let(:allow_blank) { nil }

    let(:params_block) do
      lambda do
        subject.param :boolean, type: 'boolean', required: required, allow_blank: allow_blank
      end
    end

    it 'should be :ok when param value is true' do
      response = get(action_name, params: { boolean: true })
      expect(response).to have_http_status(:ok)
    end

    it 'should be :ok when param value is false' do
      response = get(action_name, params: { boolean: false })
      expect(response).to have_http_status(:ok)
    end

    it 'should be :ok when param value is nil' do
      response = get(action_name, params: { boolean: nil })
      expect(response).to have_http_status(:ok)
    end

    it 'should be :ok when param is not present and allow_blank is default' do
      response = get(action_name)
      expect(response).to have_http_status(:ok)
    end

    it 'should accept "y", "yes", "t" and "true" as value and convert to true' do
      %w[y yes t true].each do |value|
        response = get(action_name, params: { boolean: value })
        expect(response).to have_http_status(:ok)
        expect(controller.params[:boolean]).to eq(true)
      end
    end

    it 'should accept "n", "no", "f" and "false" as value and convert to false' do
      %w[n no f false].each do |value|
        response = get(action_name, params: { boolean: value })
        expect(response).to have_http_status(:ok)
        expect(controller.params[:boolean]).to eq(false)
      end
    end

    it 'should not accept invalid value' do
      response = get(action_name, params: { boolean: 'John' })
      expect(response).to have_http_status(:unprocessable_entity)

      response = get(action_name, params: { boolean: 1 })
      expect(response).to have_http_status(:unprocessable_entity)
    end

    context 'when :required is true' do
      let(:required) { true }

      it 'should not accept missing param' do
        response = get(action_name)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should accept nil value' do
        response = get(action_name, params: { boolean: nil })
        expect(response).to have_http_status(:ok)
      end

      it 'should accept blank string' do
        response = get(action_name, params: { boolean: '' })
        expect(response).to have_http_status(:ok)
      end

      it 'should not accept invalid value' do
        response = get(action_name, params: { boolean: 'John' })
        expect(response).to have_http_status(:unprocessable_entity)
      end

      context 'and :allow_blank is true' do
        let(:allow_blank) { true }

        it 'should not accept missing param' do
          response = get(action_name)
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'should accept nil value' do
          response = get(action_name, params: { boolean: nil })
          expect(response).to have_http_status(:ok)
        end

        it 'should accept blank string' do
          response = get(action_name, params: { boolean: '' })
          expect(response).to have_http_status(:ok)
        end

        it 'should not accept invalid value' do
          response = get(action_name, params: { boolean: 'John' })
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'and :allow_blank is false' do
        let(:allow_blank) { false }

        it 'should not accept missing param' do
          response = get(action_name)
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'should not accept nil value' do
          response = get(action_name, params: { boolean: nil })
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'should not accept blank string' do
          response = get(action_name, params: { boolean: '' })
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'should not accept invalid value' do
          response = get(action_name, params: { boolean: 'John' })
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
