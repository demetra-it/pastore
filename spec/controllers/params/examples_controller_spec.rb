# frozen_string_literal: true

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
end
