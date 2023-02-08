# frozen_string_literal: true

RSpec.shared_context 'controller for params specs' do
  let(:action_name) { SecureRandom.hex(32) }
  let(:params_block) { -> {} }

  before :each do
    subject.class_eval do
      include Pastore::Params
    end

    my_action = action_name
    routes.draw do
      get my_action, to: "params/examples##{my_action}"
    end

    params_block.call

    subject.define_method action_name do
      render json: { message: 'ok' }
    end
  end
end
