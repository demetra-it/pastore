# frozen_string_literal: true

module Params
  class ObjectParamsTestController < ActionController::API
    include Pastore::Params
  end
end

# rubocop:disable Metrics/BlockLength
RSpec.describe Params::ObjectParamsTestController, type: :controller do
  subject { described_class }
  include_context 'controller for params specs'

  context 'when type is :object' do
    let(:params_block) do
      lambda do
        subject.param :object, type: 'object'
      end
    end

    it 'should be :ok when param is missing' do
      response = get(action_name)
      expect(response).to have_http_status(:ok)
    end

    it 'should be :ok when param is nil' do
      response = get(action_name, params: { object: nil })
      expect(response).to have_http_status(:ok)
    end

    it 'should be :ok when param is blank' do
      response = get(action_name, params: { object: '' })
      expect(response).to have_http_status(:ok)
    end

    it 'should be :ok when param is valid object' do
      response = get(action_name, params: { object: { name: 'John' } })
      expect(response).to have_http_status(:ok)
    end

    it 'should convert param value to object' do
      get(action_name, params: { object: { name: 'John' } })
      expect(controller.params[:object].as_json).to be_a(Hash)
      expect(controller.params[:object][:name]).to eq('John')
    end

    it 'should convert JSON string to object' do
      value = { name: 'John', age: 25 }.as_json
      get(action_name, params: { object: value.to_json })
      expect(controller.params[:object].as_json).to be_a(Hash)
      expect(controller.params[:object].as_json).to eq(value)
    end

    context 'when :required is true' do
      let(:params_block) do
        lambda do
          subject.param :object, type: 'object', required: true
        end
      end

      it 'should not accept missing param' do
        response = get(action_name)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should accept nil value' do
        response = get(action_name, params: { object: nil })
        expect(response).to have_http_status(:ok)
      end

      it 'should accept blank string' do
        response = get(action_name, params: { object: '' })
        expect(response).to have_http_status(:ok)
      end

      it 'should convert param value to object' do
        get(action_name, params: { object: { name: 'John' } })
        expect(controller.params[:object].as_json).to be_a(Hash)
        expect(controller.params[:object][:name]).to eq('John')
      end

      it 'should not accept invalid value' do
        response = get(action_name, params: { object: 'invalid' })
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should convert JSON string to object' do
        value = { name: 'John', age: 25 }.as_json
        get(action_name, params: { object: value.to_json })
        expect(controller.params[:object].as_json).to be_a(Hash)
        expect(controller.params[:object].as_json).to eq(value)
      end
    end

    context 'when :allow_blank is false' do
      let(:params_block) do
        lambda do
          subject.param :object, type: 'object', allow_blank: false
        end
      end

      it 'should not accept missing param' do
        response = get(action_name)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should not accept nil value' do
        response = get(action_name, params: { object: nil })
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should not accept blank string' do
        response = get(action_name, params: { object: '' })
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should convert param value to object' do
        get(action_name, params: { object: { name: 'John' } })
        expect(controller.params[:object].as_json).to be_a(Hash)
        expect(controller.params[:object][:name]).to eq('John')
      end

      it 'should not accept invalid value' do
        response = get(action_name, params: { object: 'invalid' })
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should convert JSON string to object' do
        value = { name: 'John', age: 25 }.as_json
        get(action_name, params: { object: value.to_json })
        expect(controller.params[:object].as_json).to be_a(Hash)
        expect(controller.params[:object].as_json).to eq(value)
      end
    end

    context 'when a :default is provided' do
      let(:params_block) do
        lambda do
          subject.param :object, type: 'object', default: { name: 'John' }
        end
      end

      it 'should set the param to default value when is missing' do
        get(action_name)
        expect(controller.params[:object][:name]).to eq('John')
      end

      it 'should not set the param to default value when is nil' do
        get(action_name, params: { object: nil })
        expect(controller.params[:object]).to be_blank
      end

      it 'should not set the param to default value when is blank' do
        get(action_name, params: { object: '' })
        expect(controller.params[:object]).to be_blank
      end

      it 'should rais Pastore::Params::InvalidValueError when default value is invalid' do
        expect do
          subject.param :object, type: 'object', default: 'invalid'
        end.to raise_error(Pastore::Params::InvalidValueError)
      end
    end

    context 'when a :modifier is given' do
      let(:params_block) do
        lambda do
          subject.param :object, type: 'object', modifier: lambda { |value|
            value[:name] = value[:name] == 'John' ? 'Doe' : 'Unknown'
            value
          }
        end
      end

      it 'should allow to manipulate the param value' do
        get(action_name, params: { object: { name: 'John' } })
        expect(controller.params[:object][:name]).to eq('Doe')

        get(action_name, params: { object: { name: 'Jane' } })
        expect(controller.params[:object][:name]).to eq('Unknown')
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
