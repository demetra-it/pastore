# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec.describe Params::ExamplesController, type: :controller do
  subject { described_class }

  include_context 'controller for params specs'

  context 'when not specified' do
    let(:default_params) { { name: 'John' } }
    let(:params_block) do
      lambda do
        subject.param :name, type: String, default: default_params[:name]
      end
    end

    it 'should not have a scope' do
      get action_name
      expect(controller.params[:name]).to eq(default_params[:name])
    end

    it 'should validate the param in main params scope' do
      get action_name, params: { name: 123 }
      expect(controller.params[:name]).to eq('123')
    end

    it 'should not find the param in a different scope' do
      get action_name, params: { custom_scope: { name: 123 } }
      expect(controller.params[:name]).to eq(default_params[:name])
    end
  end

  context 'when specified' do
    let(:default_params) { { name: 'John' } }
    let(:params_block) do
      lambda do
        subject.param :name, type: String, default: default_params[:name],
                             scope: :custom_scope
      end
    end

    it 'should leave intact params out of the specified scope with the same name' do
      get action_name
      expect(controller.params[:name]).to be_nil
    end

    it 'should validate the param in specified scope' do
      get action_name
      expect(controller.params[:custom_scope][:name]).to eq(default_params[:name])
    end
  end

  context 'when multilevel scope is specified' do
    let(:default_params) { { name: 'John' } }
    let(:params_block) do
      lambda do
        subject.param :name, type: String, default: default_params[:name],
                             scope: %i[custom_scope nested_scope]
      end
    end

    it 'should leave intact params out of the specified scope with the same name' do
      get action_name
      expect(controller.params[:name]).to be_nil
    end

    it 'should validate the param in specified scope' do
      get action_name
      expect(controller.params[:custom_scope][:nested_scope][:name]).to eq(default_params[:name])
    end

    it 'when parameters are not correctly nested, should return :bad_schema error' do
      get action_name, params: { custom_scope: { nested_scope: 123 } }

      expect(controller.params[:custom_scope][:nested_scope]).to eq('123')

      errors = json_body['errors']
      expect(errors).to have_key('custom_scope.nested_scope.name')
      expect(errors['custom_scope.nested_scope.name'].any? { |x| x['error'] == 'bad_schema' }).to be_truthy
    end
  end
end
# rubocop:enable Metrics/BlockLength
