# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec.describe Pastore::Guards::Settings do
  subject { described_class.new }

  describe '#strategy' do
    it 'should return :deny by default' do
      expect(subject.strategy).to eq :deny
    end

    it 'should change to :allow when #use_allow_strategy! is called' do
      subject.use_allow_strategy!
      expect(subject.strategy).to eq :allow
    end
  end

  describe '#permit_role' do
    let(:roles) { %i[admin user] }

    it 'should add the roles to @buffer[:permitted_roles] and keep them in buffer' do
      subject.permit_role(*roles)
      expect(subject.instance_eval { @buffer[:permitted_roles] }).to eq(roles.map(&:to_s))
    end

    it 'when called multiple times, should keep only the last value' do
      subject.permit_role(*roles)
      subject.permit_role(:guest)
      expect(subject.instance_eval { @buffer[:permitted_roles] }).to eq(%w[guest])
    end

    it 'should be saved to actions when #save_guards_for is called and removed from buffer' do
      subject.permit_role(*roles)
      subject.save_guards_for(:myaction)
      expect(subject.instance_eval { @buffer[:permitted_roles] }).to be_nil
      expect(subject.instance_eval { @actions[:myaction][:permitted_roles] }).to eq(roles.map(&:to_s))
    end

    it 'should raise an error when the same role is both permitted and denied' do
      subject.deny_role(*roles)
      expect { subject.permit_role(*roles) }.to raise_error(Pastore::Guards::RoleConflictError)
    end

    it 'should raise an error when #authorize_with is already specified' do
      subject.authorize_with(:myauth)
      expect { subject.permit_role(*roles) }.to raise_error(Pastore::Guards::RoleConflictError)
    end
  end

  describe '#deny_roles' do
    let(:roles) { %i[admin user] }

    it 'should add the roles to @buffer[:denied_roles] and keep them in buffer' do
      subject.deny_role(*roles)
      expect(subject.instance_eval { @buffer[:denied_roles] }).to eq(roles.map(&:to_s))
    end

    it 'when called multiple times, should keep only the last value' do
      subject.deny_role(*roles)
      subject.deny_role(:guest)
      expect(subject.instance_eval { @buffer[:denied_roles] }).to eq(%w[guest])
    end

    it 'should be saved to actions when #save_guards_for is called and removed from buffer' do
      subject.deny_role(*roles)
      subject.save_guards_for(:myaction)
      expect(subject.instance_eval { @buffer[:denied_roles] }).to be_nil
      expect(subject.instance_eval { @actions[:myaction][:denied_roles] }).to eq(roles.map(&:to_s))
    end

    it 'should raise an error when the same role is both permitted and denied' do
      subject.permit_role(*roles)
      expect { subject.deny_role(*roles) }.to raise_error(Pastore::Guards::RoleConflictError)
    end

    it 'should raise an error when #authorize_with is already specified' do
      subject.authorize_with(:myauth)
      expect { subject.deny_role(*roles) }.to raise_error(Pastore::Guards::RoleConflictError)
    end
  end

  describe '#authorize_with' do
    it 'should accept a block as argument' do
      expect { subject.authorize_with { true } }.not_to raise_error
    end

    it 'should accept a String or Symbol as argument' do
      expect { subject.authorize_with(:my_method) }.not_to raise_error
    end

    it 'should raise and ArgumentError if no argument or a wrong argument type is given' do
      expect { subject.authorize_with(1) }.to raise_error(ArgumentError)
      expect { subject.authorize_with }.to raise_error(ArgumentError)
    end

    it 'shoud save the lambda to @buffer[:authorization_lambda] and keep it in buffer' do
      subject.authorize_with { true }
      expect(subject.instance_eval { @buffer[:authorization_lambda] }).to be_a(Proc)
    end

    it 'when called multiple times, should keep only the last value' do
      mylambda1 = -> { false }
      mylambda2 = -> { true }

      subject.authorize_with(&mylambda1)
      subject.authorize_with(&mylambda2)

      expect(subject.instance_eval { @buffer[:authorization_lambda] }).not_to eq(mylambda1)
      expect(subject.instance_eval { @buffer[:authorization_lambda] }).to eq(mylambda2)
    end

    it 'should be saved to actions when #save_guards_for is called and removed from buffer' do
      mylambda = -> { true }

      subject.authorize_with(&mylambda)
      subject.save_guards_for(:myaction)
      expect(subject.instance_eval { @buffer[:authorization_lambda] }).to be_nil
      expect(subject.instance_eval { @actions[:myaction][:authorization_lambda] }).to eq(mylambda)
    end

    it 'should raise an error when #permit_role is are already specified' do
      subject.permit_role(:admin)
      expect { subject.authorize_with { true } }.to raise_error(Pastore::Guards::RoleConflictError)
    end

    it 'should raise an error when #deny_role is are already specified' do
      subject.deny_role(:admin)
      expect { subject.authorize_with { true } }.to raise_error(Pastore::Guards::RoleConflictError)
    end
  end

  describe '#save_guards_for' do
    let(:action_name) { SecureRandom.hex(32).to_sym }

    before :each do
      # Ensure to have a clean subject
      subject.reset_buffer!
    end

    it 'should do nothing if no guards are set' do
      subject.save_guards_for(action_name)
      expect(subject.instance_eval { @actions }).not_to have_key(action_name)
    end

    it 'should save :permitted_roles to @actions' do
      expect(subject.instance_eval { @actions }).not_to have_key(action_name)

      subject.permit_role(:admin)
      subject.save_guards_for(action_name)

      expect(subject.instance_eval { @actions }).to have_key(action_name)
    end

    it 'should save :denied_roles to @actions' do
      expect(subject.instance_eval { @actions }).not_to have_key(action_name)

      subject.deny_role(:user)
      subject.save_guards_for(action_name)

      expect(subject.instance_eval { @actions }).to have_key(action_name)
    end

    it 'should save :authorization_lambda to @actions' do
      expect(subject.instance_eval { @actions }).not_to have_key(action_name)

      subject.authorize_with { true }
      subject.save_guards_for(action_name)

      expect(subject.instance_eval { @actions }).to have_key(action_name)
    end

    it 'should remove :permitted_roles from @buffer' do
      subject.permit_role(:admin)

      expect(subject.instance_eval { @buffer }).not_to be_empty
      expect(subject.instance_eval { @buffer }).to have_key(:permitted_roles)

      subject.save_guards_for(action_name)

      expect(subject.instance_eval { @buffer }).to be_empty
    end

    it 'should remove :denied_roles from @buffer' do
      subject.deny_role(:user)

      expect(subject.instance_eval { @buffer }).not_to be_empty
      expect(subject.instance_eval { @buffer }).to have_key(:denied_roles)

      subject.save_guards_for(action_name)

      expect(subject.instance_eval { @buffer }).to be_empty
    end

    it 'should remove :authorization_lambda from @buffer' do
      subject.authorize_with { true }

      expect(subject.instance_eval { @buffer }).not_to be_empty
      expect(subject.instance_eval { @buffer }).to have_key(:authorization_lambda)

      subject.save_guards_for(action_name)

      expect(subject.instance_eval { @buffer }).to be_empty
    end
  end

  describe '#skip_guards_for' do
    let(:action_name) { SecureRandom.hex(32).to_sym }

    it 'should save actions for which guards should be skipped to @skipped_guards' do
      subject.skip_guards_for(action_name)
      expect(subject.instance_eval { @skipped_guards }).to include(action_name)
    end

    it 'should convert actions list to symbols' do
      subject.skip_guards_for(action_name.to_s)
      expect(subject.instance_eval { @skipped_guards }).to include(action_name.to_sym)
    end

    it 'should not be cumulative' do
      subject.skip_guards_for(action_name)
      subject.skip_guards_for("#{action_name}_2")

      expect(subject.instance_eval { @skipped_guards }).not_to include(action_name)
      expect(subject.instance_eval { @skipped_guards }).to include("#{action_name}_2".to_sym)
    end
  end

  describe '#force_guards_for' do
    let(:action_name) { SecureRandom.hex(32).to_sym }

    it 'should save actions for which guards should be skipped to @forced_guards' do
      subject.force_guards_for(action_name)
      expect(subject.instance_eval { @forced_guards }).to include(action_name)
    end

    it 'should convert actions list to symbols' do
      subject.force_guards_for(action_name.to_s)
      expect(subject.instance_eval { @forced_guards }).to include(action_name.to_sym)
    end

    it 'should not be cumulative' do
      subject.force_guards_for(action_name)
      subject.force_guards_for("#{action_name}_2")

      expect(subject.instance_eval { @forced_guards }).not_to include(action_name)
      expect(subject.instance_eval { @forced_guards }).to include("#{action_name}_2".to_sym)
    end
  end

  describe '#current_role' do
    let(:controller) { Guards::EmptyController }
    let(:guards) { Guards::EmptyController.pastore_guards }

    it 'by default should return nil' do
      expect(guards.current_role(controller.new)).to be_nil
    end

    it 'should return the role with @role_detector block when provided' do
      guards.role_detector = -> { :admin }
      expect(guards.current_role(controller.new)).to eq('admin')
    end
  end

  describe '#access_granted?' do
    subject(:guards) { Guards::EmptyController.pastore_guards }
    let(:controller) { Guards::EmptyController.new }
    let(:action_name) { SecureRandom.hex(32).to_sym }

    it 'should return ture if action is specified in skip guards list' do
      guards.skip_guards_for(:index)
      expect(guards.access_granted?(controller, :index)).to be true
    end

    it 'should return true if action is not specified in force guards list' do
      guards.force_guards_for(:index)
      expect(guards.access_granted?(controller, :show)).to be true
    end

    it 'should prioritize force guards list over skip guards list' do
      guards.force_guards_for(:index)
      guards.skip_guards_for(:index)
      expect(guards.access_granted?(controller, :index)).to be false
    end

    context 'when strategy is :deny' do
      before(:each) { guards.reset! }

      it 'should return false when role is not permitted' do
        guards.permit_role(:admin)
        expect(guards.access_granted?(controller, :index)).to be false
      end

      it 'should return true when role is permitted' do
        guards.role_detector = -> { :admin }
        guards.permit_role(:admin)
        guards.save_guards_for(action_name)
        expect(guards.access_granted?(controller, action_name)).to be true
      end

      it 'should return false when role is denied' do
        guards.role_detector = -> { :admin }
        guards.deny_role(:admin)
        guards.save_guards_for(action_name)
        expect(guards.access_granted?(controller, action_name)).to be false
      end
    end

    context 'when strategy is :allow' do
      before(:each) do
        guards.reset!
        guards.use_allow_strategy!
      end

      it 'should return true by default' do
        expect(guards.access_granted?(controller, action_name)).to be true
      end

      it 'should return true when role is not denied' do
        guards.role_detector = -> { :admin }
        guards.deny_role(:user)
        guards.save_guards_for(action_name)

        expect(guards.access_granted?(controller, action_name)).to be true
      end

      it 'should return false when role is denied' do
        guards.role_detector = -> { :admin }
        guards.deny_role(:admin)
        guards.save_guards_for(action_name)

        expect(guards.access_granted?(controller, action_name)).to be false
      end
    end
  end

  describe '#reset!' do
    subject(:guards) { Guards::EmptyController.pastore_guards }

    before(:each) do
      subject.permit_role(:admin)
      subject.role_detector = -> { true }
      subject.forbidden_cbk = -> { render :forbidden }
      subject.skip_guards_for(:index)
      subject.force_guards_for(:show)
      subject.reset!
    end

    it 'should reset @buffer' do
      expect(subject.instance_eval { @buffer } ).to be_empty
    end

    it 'should reset @role_detector' do
      expect(subject.instance_eval { @role_detector }).to be_nil
    end

    it 'should reset @forbidden_cbk' do
      expect(subject.instance_eval { @forbidden_cbk }).to be_nil
    end
  end
end
# rubocop:enable Metrics/BlockLength
