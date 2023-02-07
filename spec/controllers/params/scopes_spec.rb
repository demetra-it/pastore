# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Pastore::Params scope', type: :controller do
  subject { double(Params::EmptyController) }

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
end
