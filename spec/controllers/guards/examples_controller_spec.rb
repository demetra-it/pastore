# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec.describe Guards::ExamplesController, type: :controller do
  subject { described_class }

  it { should respond_to :use_allow_strategy! }
  it { should respond_to :use_deny_strategy! }
  it { should respond_to :detect_role }
  it { should respond_to :forbidden }
  it { should respond_to :permit_role }
  it { should respond_to :deny_role }
  it { should respond_to :authorize_with }
  it { should respond_to :skip_guards }
  it { should respond_to :pastore_guards }

  it 'default strategy should be "deny"' do
    expect(subject.pastore_guards.strategy).to eq :deny
  end

  describe '#use_allow_strategy!' do
    before { subject.use_allow_strategy! }

    it 'should set the default strategy to "allow"' do
      expect(subject.pastore_guards.strategy).to eq :allow
    end
  end

  describe '#use_deny_strategy!' do
    before { subject.use_deny_strategy! }

    it 'should set the default strategy to "deny"' do
      expect(subject.pastore_guards.strategy).to eq :deny
    end
  end

  describe '#detect_role' do
    context 'when a role detector is specified' do
      subject(:controller) { described_class.new }
      let(:available_roles) { %w[admin user guest] }
      before do
        described_class.detect_role { %w[admin user guest].sample }
      end

      it 'should forbidden access to action if current role is not allowed' do
        response = get :index
        expect(response).to have_http_status :forbidden
      end

      it 'should allow access to action if current role is allowed' do
        response = get :test_permit_role
        expect(response).to have_http_status :ok
      end
    end

    context 'when no role detector is specified' do
      subject(:controller) { described_class.new }
      before { described_class.detect_role }

      it 'should return nil' do
        current_role = controller.instance_eval { self.class.pastore_guards.current_role(self) }
        expect(current_role).to be_nil
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
    it 'should accept a list of symbols' do
      expect { subject.permit_role :admin, :user }.not_to raise_error
    end

    it 'should accept a list of strings' do
      expect { subject.permit_role 'admin', 'user' }.not_to raise_error
    end

    it 'should not be cumulative' do
      subject.detect_role { :admin }
      response = get :test_cumulative_permit_role
      expect(response.status).to eq 403

      subject.detect_role { :guest }
      response = get :test_cumulative_permit_role
      expect(response.status).to eq 200
    end

    context 'when a role is allowed' do
      before { subject.detect_role { :admin } }

      it 'should allow the request' do
        respone = get :test_permit_role
        expect(respone.status).to eq 200
      end
    end

    context 'when a role is not allowed' do
      before { subject.detect_role { :guest } }

      it 'should respond with 403 Forbidden' do
        response = get :test_unpermitted_role
        expect(response.status).to eq 403
      end
    end
  end

  describe '#deny_role' do
    before :each do
      subject.pastore_guards.reset_buffer!
    end

    it 'should accept a list of symbols' do
      expect { subject.deny_role :admin, :user }.not_to raise_error
    end

    it 'should accept a list of strings' do
      expect { subject.deny_role 'admin', 'user' }.not_to raise_error
    end

    it 'should not be cumulative' do
      subject.use_allow_strategy!

      subject.detect_role { :admin }
      response = get :test_cumulative_deny_role
      expect(response.status).to eq 200

      subject.detect_role { :guest }
      response = get :test_cumulative_deny_role
      expect(response.status).to eq 403
    end

    context 'when default strategy is set to :allow' do
      before do
        subject.use_allow_strategy!
        subject.detect_role { :user }
      end

      it 'should deny the request by default if role is not denied' do
        response = get :test_denied_role
        expect(response.status).to eq 200
      end

      it 'should deny the request if the role is specified with #deny_role' do
        subject.use_allow_strategy!
        subject.detect_role { :admin }

        response = get :test_denied_role
        expect(response.status).to eq 403
      end
    end
  end

  describe '#authorize_with' do
    it 'should accept a block as parameter' do
      expect { subject.authorize_with { true } }.not_to raise_error
    end

    it 'should accept a symbol or string as parameter' do
      expect { subject.authorize_with :custom_authorization }.not_to raise_error
      expect { subject.authorize_with 'custom_authorization' }.not_to raise_error
    end

    it 'should not accept other types of parameters' do
      expect { subject.authorize_with 123 }.to raise_error ArgumentError
    end

    context 'when is set' do
      before { subject.use_deny_strategy! }

      it 'should permit when authorize logic returns true' do
        response = get :test_authorized_with_permitted
        expect(response.status).to eq 200
      end

      it 'should deny when authorize logic returns false' do
        response = get :test_authorized_with_denied
        expect(response.status).to eq 403
      end

      it 'should use custom authorization method when specified' do
        response = get :test_authorized_with_method
        expect(response.status).to eq 403

        subject.define_method(:custom_authorization) { true }
        response = get :test_authorized_with_method
        expect(response.status).to eq 200
      end
    end
  end

  describe '#skip_guards' do
    it 'should accept a list of actions' do
      expect { subject.skip_guards :index, :show }.not_to raise_error
    end

    it 'should accept :except key' do
      expect { subject.skip_guards except: :index }.not_to raise_error
    end

    it ':except key could be an array, as string or a symbol' do
      expect { subject.skip_guards except: %i[index show] }.not_to raise_error
      expect { subject.skip_guards except: 'index' }.not_to raise_error
      expect { subject.skip_guards except: :index }.not_to raise_error
    end

    it 'should skip guards for specified actions' do
      # Switch to deny strategy
      subject.use_deny_strategy!

      # Clear skip guards list
      subject.skip_guards

      # This action should be denied based on its configuration
      response = get :test_authorized_with_denied
      expect(response.status).to eq 403

      # Now we'll add this action to the skip guards list
      subject.skip_guards :test_authorized_with_denied

      # This action should be allowed now
      response = get :test_authorized_with_denied
      expect(response.status).to eq 200
    end
  end
end
# rubocop:enable Metrics/BlockLength
