# frozen_string_literal: true

require_relative 'support/config/application'
require 'pastore'
require 'rspec/rails'

Dir[File.join(__dir__, 'support', '**', '*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Turn off ActiveRecord support
  config.use_active_record = false

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  # config.filter_rails_from_backtrace!
end

# Configure Shoulda::Matchers to use RSpec as the test framework
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec

    with.library :rails
  end
end
