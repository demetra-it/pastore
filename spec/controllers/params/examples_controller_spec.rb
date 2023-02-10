# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec.describe Params::ExamplesController, type: :controller do
  subject { described_class }
  include_context 'controller for params specs'

  it { should include Pastore::Params }
  it { should respond_to :pastore_params }
  it { should respond_to :param }
  it { should respond_to :on_invalid_params }

  it 'should raise Pastore::Params::InvalidTypeError when invalid param type is provided' do
    expect do
      subject.param :name, type: 'invalid'
    end.to raise_error(Pastore::Params::InvalidParamTypeError)
  end

  context 'when no params have been specified' do
    it 'should return a 200 status code' do
      response = get(action_name)
      expect(response).to have_http_status(:ok)
    end
  end

  context 'when :on_invalid_params is provided' do
    let(:result_message) { { 'message' => SecureRandom.hex(20) } }
    let(:params_block) do
      lambda do
        subject.param :item, type: :object

        my_result = result_message
        subject.on_invalid_params do
          render json: my_result
        end
      end
    end

    it 'should set :invalid_params_cbk for current controller' do
      expect(subject.pastore_params.invalid_params_cbk).not_to be_nil
      expect(subject.pastore_params.invalid_params_cbk).to be_a(Proc)
    end

    it 'should return a 422 status code if a param is invalid' do
      response = get(action_name, params: { item: 'invalid' })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body).to eq(result_message)
    end

    it 'should not be called when all params are ok' do
      response = get(action_name, params: { name: 'John' })
      expect(response).to have_http_status(:ok)
      expect(json_body).not_to eq(result_message)
    end
  end
end
# rubocop:enable Metrics/BlockLength
