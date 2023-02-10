# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec.describe Pastore::Params::Settings do
  subject { described_class.new(Params::EmptyController) }

  describe '#reset!' do
    it 'should reset @actions' do
      subject.instance_variable_set(:@actions, :foo)
      subject.reset!
      expect(subject.instance_variable_get(:@actions)).to eq({})
    end

    it 'should reset @invalid_params_cbk' do
      subject.instance_variable_set(:@invalid_params_cbk, :foo)
      subject.reset!
      expect(subject.instance_variable_get(:@invalid_params_cbk)).to be_nil
    end

    it 'should reset @buffer' do
      subject.instance_variable_set(:@buffer, :foo)
      subject.reset!
      expect(subject.instance_variable_get(:@buffer)).to eq([])
    end
  end

  describe '#reset_buffer!' do
    it 'should reset @buffer' do
      subject.instance_variable_set(:@buffer, :foo)
      subject.reset_buffer!
      expect(subject.instance_variable_get(:@buffer)).to eq([])
    end
  end

  describe '#invalid_params_cbk' do
    let(:main_class) { Class.new(Params::EmptyController) }
    let(:inherit_class) { Class.new(main_class) }
    let(:invalid_params_cbk) { -> {} }

    before :each do
      main_class.on_invalid_params(&invalid_params_cbk)
    end

    it 'should return the callback set with #invalid_params_cbk=' do
      cbk = -> {}
      inherit_class.on_invalid_params(&cbk)
      expect(inherit_class.pastore_params.invalid_params_cbk).to eq(cbk)
    end

    it 'should fallback to parent settings if not set' do
      expect(inherit_class.pastore_params.invalid_params_cbk).to eq(invalid_params_cbk)
    end
  end

  describe '#add' do
    before :each do
      subject.reset!
    end

    it 'should create a new ActionParam and add it to @buffer' do
      expect { subject.add(:foo) }.to change { subject.instance_variable_get(:@buffer).size }.by(1)
      expect(subject.instance_variable_get(:@buffer).last).to be_a Pastore::Params::ActionParam
    end

    it 'should not change @actions' do
      expect { subject.add(:foo) }.not_to(change { subject.instance_variable_get(:@actions) })
    end

    it 'should raise an error if the param is already defined' do
      subject.add(:foo)
      expect { subject.add(:foo) }.to raise_error(Pastore::Params::ParamAlreadyDefinedError)
    end
  end

  describe '#save_for' do
    before :each do
      subject.reset!
    end

    it 'should save the settings in @buffer for the given action' do
      subject.add(:foo)
      subject.add(:bar)

      buffered_params = subject.instance_variable_get(:@buffer).dup

      expect { subject.save_for(:index) }.to(change { subject.instance_variable_get(:@actions) })
      expect(subject.instance_variable_get(:@actions)[:index]).to eq(buffered_params)
    end

    it 'should reset the value of @buffer' do
      subject.add(:foo)
      subject.add(:bar)

      expect { subject.save_for(:index) }.to(change { subject.instance_variable_get(:@buffer) })
      expect(subject.instance_variable_get(:@buffer)).to be_empty
    end
  end

  describe '#validate' do
    let(:controller_class) { Class.new(Params::EmptyController) }
    let(:controller) { controller_class.new }

    it 'should return an empty array if the action has no params' do
      result = subject.validate(controller, :index)
      expect(result).to be_empty
    end

    it 'should return an empty array if the action has params but no invalid params' do
      subject.add(:foo)
      subject.save_for(:index)

      result = subject.validate({}, :index)
      expect(result).to be_empty
    end
  end
end
# rubocop:enable Metrics/BlockLength
