# frozen_string_literal: true

module Params
  class StringParamsTestController < ActionController::API
    include Pastore::Params
  end
end

# =================================================================
# Shared examples
# =================================================================
# rubocop:disable Metrics/BlockLength
RSpec.shared_examples '(type: :string) converts other types to string' do
  it 'should be ok when param value is an integer, float or a object' do
    response = get(action_name, params: { string: 25 })
    expect(response).to have_http_status(:ok)

    response = get(action_name, params: { string: 25.5 })
    expect(response).to have_http_status(:ok)

    response = get(action_name, params: { string: { a: 1, b: 2 } })
    expect(response).to have_http_status(:ok)
  end

  it 'should convert param value to string from other types' do
    value = 25
    get(action_name, params: { string: value })
    expect(controller.params[:string]).to eq(value.to_s)

    value = 25.5
    get(action_name, params: { string: 25.5 })
    expect(controller.params[:string]).to eq(value.to_s)

    value = { a: 1, b: 2 }
    get(action_name, params: { string: value })
    expect(controller.params[:string]).to be_a(String)
    expect(controller.params[:string]).to eq(value.stringify_keys.transform_values(&:to_s).to_h.to_s)

    value = DateTime.now
    get(action_name, params: { string: value })
    expect(controller.params[:string]).to be_a(String)
    expect(controller.params[:string]).to eq(value.to_s)

    value = [true, false].sample
    get(action_name, params: { string: value })
    expect(controller.params[:string]).to be_a(String)
    expect(controller.params[:string]).to eq(value.to_s)
  end
end


# =================================================================
# Tests
# =================================================================
RSpec.describe Params::StringParamsTestController, type: :controller do
  subject { described_class }

  include_context 'controller for params specs'

  context 'when type is :string' do
    let(:params_block) do
      lambda do
        subject.param :string, type: 'string'
      end
    end

    it 'should be ok when param value is a string' do
      response = get(action_name, params: { string: 'John' })
      expect(response).to have_http_status(:ok)
    end

    include_examples '(type: :string) converts other types to string'

    context 'when :required is true' do
      let(:params_block) do
        lambda do
          subject.param :string, type: 'string', required: true
        end
      end

      it 'should not accept missing param' do
        response = get(action_name)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should accept nil param' do
        response = get(action_name, params: { string: nil })
        expect(response).to have_http_status(:ok)
      end

      it 'should accept blank param' do
        response = get(action_name, params: { string: '' })
        expect(response).to have_http_status(:ok)
      end

      it 'should accept string param' do
        response = get(action_name, params: { string: 'John' })
        expect(response).to have_http_status(:ok)
      end

      include_examples '(type: :string) converts other types to string'
    end

    context 'when :allow_blank is false' do
      let(:params_block) do
        lambda do
          subject.param :string, type: 'string', allow_blank: false
        end
      end

      it 'should not accept missing param' do
        response = get(action_name)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should not accept blank param' do
        response = get(action_name, params: { string: '' })
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should accept string param' do
        response = get(action_name, params: { string: 'John' })
        expect(response).to have_http_status(:ok)
      end

      include_examples '(type: :string) converts other types to string'
    end

    context 'when :required is true and :allow_blank is false' do
      let(:params_block) do
        lambda do
          subject.param :string, type: 'string', required: true, allow_blank: false
        end
      end

      it 'should not accept missing param' do
        response = get(action_name)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should not accept nil param' do
        response = get(action_name, params: { string: nil })
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should not accept blank param' do
        response = get(action_name, params: { string: '' })
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should accept string param' do
        response = get(action_name, params: { string: 'John' })
        expect(response).to have_http_status(:ok)
      end

      include_examples '(type: :string) converts other types to string'
    end

    describe ':format option' do
      context 'when :format is not set' do
        let(:params_block) do
          lambda do
            subject.param :string, type: 'string'
          end
        end

        it 'should accept any string param' do
          value = SecureRandom.base64(10)
          response = get(action_name, params: { string: value })
          expect(response).to have_http_status(:ok)
          expect(controller.params[:string]).to eq(value)
        end

        it 'should accept string param with special characters' do
          value = 'John#&!*'
          response = get(action_name, params: { string: value })
          expect(response).to have_http_status(:ok)
          expect(controller.params[:string]).to eq(value)
        end
      end

      context 'when :format regexp is specified' do
        let(:params_block) do
          lambda do
            subject.param :string, type: 'string', format: /\A[a-z]+\z/
          end
        end

        it 'should accept string param that matches :format regexp' do
          value = 'john'
          response = get(action_name, params: { string: value })
          expect(response).to have_http_status(:ok)
          expect(controller.params[:string]).to eq(value)
        end

        it 'should not accept string param that does not match the regexp' do
          value = 'John'
          response = get(action_name, params: { string: value })
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe ':in option' do
      context 'when :in is not set' do
        let(:params_block) do
          lambda do
            subject.param :string, type: 'string'
          end
        end

        it 'should accept any string param' do
          value = SecureRandom.base64(10)
          response = get(action_name, params: { string: value })
          expect(response).to have_http_status(:ok)
          expect(controller.params[:string]).to eq(value)
        end
      end

      context 'when :in is specified' do
        let(:params_block) do
          lambda do
            subject.param :string, type: 'string', in: %w[John Jane]
          end
        end

        it 'should accept string param that is in :in array' do
          value = 'John'
          response = get(action_name, params: { string: value })
          expect(response).to have_http_status(:ok)
          expect(controller.params[:string]).to eq(value)
        end

        it 'should not accept string param that is not in :in array' do
          value = 'Jack'
          response = get(action_name, params: { string: value })
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe ':exclude option' do
      context 'when :exclude is not set' do
        let(:params_block) do
          lambda do
            subject.param :string, type: 'string'
          end
        end

        it 'should accept any string param' do
          value = SecureRandom.base64(10)
          response = get(action_name, params: { string: value })
          expect(response).to have_http_status(:ok)
          expect(controller.params[:string]).to eq(value)
        end
      end

      context 'when :exclude is specified' do
        let(:params_block) do
          lambda do
            subject.param :string, type: 'string', exclude: %w[John Jane]
          end
        end

        it 'should not accept string param that is in :exclude array' do
          value = 'John'
          response = get(action_name, params: { string: value })
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'should accept string param that is not in :exclude array' do
          value = 'Jack'
          response = get(action_name, params: { string: value })
          expect(response).to have_http_status(:ok)
          expect(controller.params[:string]).to eq(value)
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
