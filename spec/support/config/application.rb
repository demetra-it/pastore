# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'

Bundler.require(*Rails.groups)

module ExampleApplication
  class Application < Rails::Application
    config.api_only = true

    config.cache_classes = true
    config.eager_load = false

    # Show full error reports and disable caching.
    config.consider_all_requests_local       = true
    config.action_controller.perform_caching = false
    config.cache_store = :null_store

    # Raise exceptions instead of rendering exception templates.
    config.action_dispatch.show_exceptions = false

    # Disable request forgery protection in test environment.
    config.action_controller.allow_forgery_protection = false

    # Print deprecation notices to the stderr.
    config.active_support.deprecation = :stderr

    # Raise exceptions for disallowed deprecations.
    config.active_support.disallowed_deprecation = :raise

    # Tell Active Support which deprecation messages to disallow.
    config.active_support.disallowed_deprecation_warnings = []
  end
end

Rails.application.credentials.secret_key_base ||= SecureRandom.hex(64)

Rails.application.initialize!

require_relative 'routes'
