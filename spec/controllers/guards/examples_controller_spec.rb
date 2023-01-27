# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec.describe Guards::ExamplesController, type: :controller do
  subject { described_class }

  it { should respond_to :use_allow_strategy! }
  it { should respond_to :use_deny_strategy! }
  it { should respond_to :detect_role }
  it { should respond_to :pastore_default_strategy }

  it 'default strategy should be "deny"' do
    expect(subject.pastore_default_strategy).to eq :deny
  end

  describe '#use_allow_strategy!' do
    before { subject.use_allow_strategy! }

    it 'should set the default strategy to "allow"' do
      expect(subject.pastore_default_strategy).to eq :allow
    end
  end

  describe '#use_deny_strategy!' do
    before { subject.use_deny_strategy! }

    it 'should set the default strategy to "deny"' do
      expect(subject.pastore_default_strategy).to eq :deny
    end
  end

  describe '#detect_role' do
    context 'when a role detector is specified' do
      subject(:controller) { described_class.new }
      let(:available_roles) { %i[admin user guest] }
      before { described_class.detect_role { available_roles.sample } }

      it 'should specify the logic to use for current role detection' do
        expect(controller.instance_eval { pastore_current_role }).to be_in available_roles
      end

      pending 'should forbidden access to action if current role is not allowed'
      pending 'should allow access to action if current role is allowed'
    end

    context 'when no role detector is specified' do
      subject(:controller) { described_class.new }
      before { described_class.detect_role }

      it 'should return nil' do
        expect(controller.instance_eval { pastore_current_role }).to be_nil
      end

      context 'when a default strategy is set to :deny' do
        subject(:response) { get :index }
        let(:forbidden_body) { { status: 403, message: 'My custom forbidden message' } }

        before do
          described_class.instance_eval do
            use_deny_strategy!

            forbidden do
              render json: { status: 403, message: 'My custom forbidden message' }
            end
          end
        end

        it 'should deny access to action' do
          expect(response).to have_http_status :forbidden
        end

        it 'shoud render the custom forbidden message speficied with `forbidden` block' do
          expect(response.body).to eq forbidden_body.to_json
        end
      end
    end
  end

  describe '#permit_role' do
    pending 'should accept a list of symbols'
    pending 'should accept a list of strings'

    context 'when a role is allowed' do
      pending 'should allow the request'
    end

    context 'when a role is not allowed' do
      pending 'should respond with 403 Forbidden'
    end
  end

  describe '#authorize_with' do
    pending 'should accept a block as parameter'
    pending 'should accept a method name as parameter'

    context 'when is set' do
      pending 'should authorize the request with dynamic logic'
    end
  end
end
# rubocop:enable Metrics/BlockLength
