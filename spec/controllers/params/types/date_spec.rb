# frozen_string_literal: true

module Params
  class DateParamsTestController < ActionController::API
    include Pastore::Params
  end
end

RSpec.describe Params::DateParamsTestController, type: :controller do
  subject { described_class }
  include_context 'controller for params specs'

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
end
