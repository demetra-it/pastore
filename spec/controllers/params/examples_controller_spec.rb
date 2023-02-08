# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec.describe Params::ExamplesController, type: :controller do
  subject { described_class }

  let(:action_name) { SecureRandom.hex(32) }
  let(:params_block) { -> {} }

  before :each do
    # Add action_name to routes
    my_action = action_name
    Rails.application.routes.draw do
      namespace :params do
        resources :examples, only: [] do
          get my_action, on: :collection
        end
      end
    end

    params_block.call

    subject.define_method action_name do
      render json: { message: 'ok' }
    end
  end

  after :each do
    subject.pastore_params.reset!
  end

  it { should include Pastore::Params }
  it { should respond_to :pastore_params }
  it { should respond_to :param }
  it { should respond_to :on_invalid_params }

  context 'when no params have been specified' do
    before :each do
      subject.define_method action_name do
        render json: { message: 'ok' }
      end
    end

    it 'should return a 200 status code' do
      response = get(action_name)
      expect(response).to have_http_status(:ok)
    end
  end

  context 'when params have been specified' do
    let(:allow_blank) { true }
    let(:params) { { name: 'John', age: 25 } }

    let(:params_block) do
      lambda do
        subject.param :name, type: 'string', required: true, allow_blank: allow_blank
        subject.param :age, type: 'integer', required: true, allow_blank: allow_blank
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
