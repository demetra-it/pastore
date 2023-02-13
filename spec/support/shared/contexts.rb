# frozen_string_literal: true

RSpec.shared_context 'controller for params specs' do
  let(:action_name) { SecureRandom.hex(32).to_sym }
  let(:params_block) { -> {} }

  before :each do
    my_action = action_name
    my_controller = subject.name.underscore.gsub(/_controller$/, '')
    routes.draw do
      get my_action, to: "#{my_controller}##{my_action}"
    end

    params_block.call

    subject.define_method action_name do
      render json: { message: 'ok' }
    end
  end

  after :each do
    subject.pastore_params.reset!
  end
end
