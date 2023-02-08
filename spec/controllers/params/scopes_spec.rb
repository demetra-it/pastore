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

  context 'when scope block is used to validate params in a specific scope' do
    let(:default_params) { { param1: 'John', param2: 'Doe', param3: 'Random string' } }
    let(:params_block) do
      lambda do
        subject.param :param1, type: String, default: default_params[:param1]

        subject.scope :custom_scope do
          subject.param :param2, type: String, default: default_params[:param2]
        end

        subject.scope :custom_scope2 do
          subject.param :param3, type: String, default: default_params[:param3]
        end
      end
    end

    it 'should validate the param in different scopes' do
      get action_name
      expect(controller.params[:param1]).to eq(default_params[:param1])
      expect(controller.params[:custom_scope][:param2]).to eq(default_params[:param2])
      expect(controller.params[:custom_scope2][:param3]).to eq(default_params[:param3])
    end

    context 'when :scope option is used along with scope block' do
      it 'should raise Pastore::Params::ScopeConflictError' do
        scope_conflict_lambda = lambda do
          subject.scope :custom_scope do
            subject.param :param1, type: String, scope: :custom_scope
          end
        end

        expect(&scope_conflict_lambda).to raise_error(Pastore::Params::ScopeConflictError)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
