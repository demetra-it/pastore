# frozen_string_literal: true

module Params
  class NumericParamsTestController < ActionController::API
    include Pastore::Params
  end
end

# rubocop:disable Metrics/BlockLength
RSpec.describe Params::NumericParamsTestController, type: :controller do
  subject { described_class }
  include_context 'controller for params specs'

  context 'when type is :number' do
    let(:params_block) do
      lambda do
        subject.param :number, type: 'number'
        subject.param :integer, type: 'integer'
        subject.param :float, type: 'float'
      end
    end

    it 'should be ok when param value is an integer' do
      response = get(action_name, params: { number: 25 })
      expect(response).to have_http_status(:ok)
    end

    it 'should be ok when param value is a float' do
      response = get(action_name, params: { number: 25.5 })
      expect(response).to have_http_status(:ok)
    end

    it 'should return a 422 when param value is a string or an object' do
      response = get(action_name, params: { number: 'John' })
      expect(response).to have_http_status(:unprocessable_entity)

      response = get(action_name, params: { number: { a: 1, b: 2 } })
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'should be :ok when param value is nil' do
      response = get(action_name, params: { number: nil })
      expect(response).to have_http_status(:ok)
    end

    it 'should be :ok when param is not present and allow_blank is default' do
      response = get(action_name)
      expect(response).to have_http_status(:ok)
    end

    it 'should accept also :integer and :float as alias type of :number' do
      response = get(action_name, params: { integer: 25 })
      expect(response).to have_http_status(:ok)

      response = get(action_name, params: { float: 25.5 })
      expect(response).to have_http_status(:ok)
    end

    describe ':min and :max options' do
      let(:range) { 10..20 }
      let(:params_block) do
        lambda do
          subject.param :number, type: 'number', min: range.min, max: range.max
        end
      end

      it 'should return a 422 when param value is less than :min' do
        response = get(action_name, params: { number: range.min - 1 })
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should return a 422 when param value is greater than :max' do
        response = get(action_name, params: { number: range.max + 1 })
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe ':clamp option' do
      let(:range) { 10..20 }
      let(:params_block) do
        lambda do
          subject.param :number, type: 'number', clamp: range
        end
      end

      it 'should clamp the value to lower bound if it is less than lower bound' do
        response = get(action_name, params: { number: range.min - 1 })
        expect(response).to have_http_status(:ok)
        expect(controller.params[:number]).to eq(range.min)
      end

      it 'should clamp the value to upper bound if it is greater than upper bound' do
        response = get(action_name, params: { number: range.max + 1 })
        expect(response).to have_http_status(:ok)
        expect(controller.params[:number]).to eq(range.max)
      end
    end

    describe ':allow_blank option' do
      let(:allow_blank) { nil }
      let(:required) { nil }

      let(:params_block) do
        lambda do
          subject.param :number, type: 'number', required: required, allow_blank: allow_blank
        end
      end

      it 'by default should accept missing param' do
        response = get(action_name)
        expect(response).to have_http_status(:ok)
      end

      it 'by default should accept nil value' do
        response = get(action_name, params: { number: nil })
        expect(response).to have_http_status(:ok)
      end

      it 'should accept blank string' do
        response = get(action_name, params: { number: '' })
        expect(response).to have_http_status(:ok)
      end

      it 'should not accept invalid value' do
        response = get(action_name, params: { number: 'John' })
        expect(response).to have_http_status(:unprocessable_entity)
      end

      context 'when allow_blank is true' do
        let(:allow_blank) { true }

        it 'should accept missing param' do
          response = get(action_name)
          expect(response).to have_http_status(:ok)
        end

        it 'should accept nil value' do
          response = get(action_name, params: { number: nil })
          expect(response).to have_http_status(:ok)
        end

        it 'should accept blank string' do
          response = get(action_name, params: { number: '' })
          expect(response).to have_http_status(:ok)
        end

        it 'should not accept invalid value' do
          response = get(action_name, params: { number: 'John' })
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'when allow_blank is false' do
        let(:allow_blank) { false }

        it 'should not accept missing param' do
          response = get(action_name)
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'should not accept nil value' do
          response = get(action_name, params: { number: nil })
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'should not accept blank string' do
          response = get(action_name, params: { number: '' })
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'should not accept invalid value' do
          response = get(action_name, params: { number: 'John' })
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
