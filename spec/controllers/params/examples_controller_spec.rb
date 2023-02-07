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

    describe 'required params' do
      it 'should return a 422 status code if a required param is missing' do
        response = get(action_name)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should return a 200 status code if all required params are present' do
        response = get(action_name, params: params)
        expect(response).to have_http_status(:ok)
      end

      it 'should not alter the params' do
        get(action_name, params: params)
        expect(controller.params[:name]).to eq(params[:name])
        expect(controller.params[:age]).to eq(params[:age])
      end

      context 'when :allow_blank is true' do
        let(:allow_blank) { true }

        it 'blank string should be considered as present' do
          params[:name] = ''
          response = get(action_name, params: params)
          expect(response).to have_http_status(:ok)
        end

        it 'nil value for string should be considered as present' do
          params[:name] = nil
          response = get(action_name, params: params)
          expect(response).to have_http_status(:ok)
        end

        it 'nil value for integer should be considered as present' do
          params[:age] = nil
          response = get(action_name, params: params)
          expect(response).to have_http_status(:ok)
        end

        it 'missing string param should be considered as missing' do
          params.delete :name
          response = get(action_name, params: params)
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'missing integer param should be considered as missing' do
          params.delete :age
          response = get(action_name, params: params)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'when :allow_blank is false' do
        let(:allow_blank) { false }

        it 'blank string should be considered as missing' do
          params[:name] = ''
          response = get(action_name, params: params)
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'nil should be considered as missing' do
          params[:name] = nil
          response = get(action_name, params: params)
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'nil value for integer should be considered as missing' do
          params[:age] = nil
          response = get(action_name, params: params)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe ':type option' do
      let(:params) { { string: 'John', numeric: 25, object: { a: 1, b: 2 }, boolean: true } }

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

        it 'should be ok when param value is an integer, float or a object' do
          response = get(action_name, params: { string: 25 })
          expect(response).to have_http_status(:ok)

          response = get(action_name, params: { string: 25.5 })
          expect(response).to have_http_status(:ok)

          response = get(action_name, params: { string: { a: 1, b: 2 } })
          expect(response).to have_http_status(:ok)
        end
      end

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

      context 'when type is :date' do
        pending 'should be :ok when param is missing'
        pending 'should be :ok when param is nil'
        pending 'should be :ok when param is blank'
        pending 'should be :ok when param is valid date'
        pending 'should convert param value to date'
        pending 'should not accept invalid value'

        context 'when :required is true' do
          pending 'should not accept missing param'
          pending 'should accept nil value'
          pending 'should accept blank string'
          pending 'should convert param value to date'
          pending 'should not accept invalid value'
        end

        context 'when :allow_blank is false' do
          pending 'should not accept missing param'
          pending 'should not accept nil value'
          pending 'should not accept blank string'
          pending 'should convert param value to date'
          pending 'should not accept invalid value'
        end
      end

      context 'when type is :object' do
        pending 'should be :ok when param is missing'
        pending 'should be :ok when param is nil'
        pending 'should be :ok when param is blank'
        pending 'should be :ok when param is valid object'
        pending 'should convert param value to object'
        pending 'should convert JSON string to object'

        context 'when :required is true' do
          pending 'should not accept missing param'
          pending 'should accept nil value'
          pending 'should accept blank string'
          pending 'should convert param value to object'
          pending 'should not accept invalid value'
          pending 'should convert JSON string to object'
        end

        context 'when :allow_blank is false' do
          pending 'should not accept missing param'
          pending 'should not accept nil value'
          pending 'should not accept blank string'
          pending 'should convert param value to object'
          pending 'should not accept invalid value'
          pending 'should convert JSON string to object'
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
