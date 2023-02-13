# frozen_string_literal: true

module Params
  class DateParamsTestController < ActionController::API
    include Pastore::Params
  end
end

# rubocop:disable Metrics/BlockLength
RSpec.describe Params::DateParamsTestController, type: :controller do
  subject { described_class }
  include_context 'controller for params specs'

  context 'when type is :date' do
    let(:params_block) do
      lambda do
        subject.param :date, type: 'date'
      end
    end

    it 'should be :ok when param is missing' do
      response = get(action_name)
      expect(response).to have_http_status(:ok)
    end

    it 'should be :ok when param is nil' do
      response = get(action_name, params: { date: nil })
      expect(response).to have_http_status(:ok)
    end

    it 'should be :ok when param is blank' do
      response = get(action_name, params: { date: '' })
      expect(response).to have_http_status(:ok)
    end

    it 'should be :ok when param is valid date' do
      response = get(action_name, params: { date: '2018-01-01 00:00:00' })
      expect(response).to have_http_status(:ok)

      response = get(action_name, params: { date: '2018-01-01' })
      expect(response).to have_http_status(:ok)

      response = get(action_name, params: { date: '2018-01-01 00:00:00 -0300' })
      expect(response).to have_http_status(:ok)

      response = get(action_name, params: { date: Time.zone.now })
      expect(response).to have_http_status(:ok)
    end

    it 'should convert param value to date' do
      get(action_name, params: { date: '2018-01-01 00:00:00' })
      expect(controller.params[:date]).to be_a(Date)
      expect(controller.params[:date]).to eq(Date.new(2018, 1, 1))
    end

    it 'should not accept invalid value' do
      response = get(action_name, params: { date: 'invalid' })
      expect(response).to have_http_status(:unprocessable_entity)

      response = get(action_name, params: { date: '2018-55-55' })
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'should accept integer value and convert it to date' do
      date = Time.now.to_i

      get(action_name, params: { date: date })
      expect(controller.params[:date]).to be_a(Date)
      expect(controller.params[:date].to_time.to_i).to eq(date)
    end

    it 'should accept float value and convert it to date' do
      date = Time.now.to_f

      get(action_name, params: { date: date })
      expect(controller.params[:date]).to be_a(Date)
      expect(controller.params[:date].to_time.to_f).to eq(date)
    end

    context 'when :required is true' do
      let(:params_block) do
        lambda do
          subject.param :date, type: 'date', required: true
        end
      end

      it 'should not accept missing param' do
        response = get(action_name)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should accept nil value' do
        response = get(action_name, params: { date: nil })
        expect(response).to have_http_status(:ok)
      end

      it 'should accept blank string' do
        response = get(action_name, params: { date: '' })
        expect(response).to have_http_status(:ok)
      end

      it 'should convert param value to date' do
        date = DateTime.now
        get(action_name, params: { date: date })
        expect(controller.params[:date]).to be_a(Date)
        expect(controller.params[:date].to_s).to eq(date.to_s)
      end

      it 'should not accept invalid value' do
        response = get(action_name, params: { date: 'invalid' })
        expect(response).to have_http_status(:unprocessable_entity)

        response = get(action_name, params: { date: '2018-55-55' })
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when :allow_blank is false' do
      let(:params_block) do
        lambda do
          subject.param :date, type: 'date', allow_blank: false
        end
      end

      it 'should not accept missing param' do
        response = get(action_name)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should not accept nil value' do
        response = get(action_name, params: { date: nil })
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should not accept blank string' do
        response = get(action_name, params: { date: '' })
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should convert param value to date' do
        date = DateTime.now
        get(action_name, params: { date: date })
        expect(controller.params[:date]).to be_a(Date)
        expect(controller.params[:date].to_s).to eq(date.to_s)
      end

      it 'should not accept invalid value' do
        response = get(action_name, params: { date: 'invalid' })
        expect(response).to have_http_status(:unprocessable_entity)

        response = get(action_name, params: { date: '2018-55-55' })
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when :default is set' do
      let(:params_block) do
        lambda do
          subject.param :date, type: 'date', default: '2018-01-01'
        end
      end

      it 'should set param value to default when param is missing' do
        response = get(action_name)
        expect(response).to have_http_status(:ok)
        expect(controller.params[:date]).to eq(Date.new(2018, 1, 1))
      end

      it 'should not set param value to default when param is nil' do
        response = get(action_name, params: { date: nil })
        expect(response).to have_http_status(:ok)
        expect(controller.params[:date]).to eq('')
      end

      it 'should not set param value to default when param is blank' do
        response = get(action_name, params: { date: '' })
        expect(response).to have_http_status(:ok)
        expect(controller.params[:date]).to eq('')
      end

      it 'should raise Pastore::Params::InvalidValueError when default value is invalid' do
        params_block = lambda do
          subject.param :date, type: 'date', default: 'invalid'
        end
        expect { params_block.call }.to raise_error(Pastore::Params::InvalidValueError)
      end
    end

    context 'when :clamp is set' do
      let(:params_block) do
        lambda do
          subject.param :date, type: 'date', clamp: '2018-01-01'..'2018-01-31'
        end
      end

      it 'should clamp param value to min when param is less than min' do
        response = get(action_name, params: { date: '2017-01-31' })
        expect(response).to have_http_status(:ok)
        expect(controller.params[:date]).to eq(Date.new(2018, 1, 1))
      end

      it 'should clamp param value to max when param is greater than max' do
        response = get(action_name, params: { date: '2020-02-01' })
        expect(response).to have_http_status(:ok)
        expect(controller.params[:date]).to eq(Date.new(2018, 1, 31))
      end

      it 'should not clamp param value when param is in range' do
        response = get(action_name, params: { date: '2018-01-15' })
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
