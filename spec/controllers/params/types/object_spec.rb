# frozen_string_literal: true

module Params
  class ObjectParamsTestController < ActionController::API
    include Pastore::Params
  end
end

# rubocop:disable Metrics/BlockLength
RSpec.describe Params::ObjectParamsTestController, type: :controller do
  subject { described_class }
  include_context 'controller for params specs'

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
# rubocop:enable Metrics/BlockLength
