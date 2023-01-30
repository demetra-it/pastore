# frozen_string_literal: true

require_relative 'lib/pastore/version'

Gem::Specification.new do |spec|
  spec.name = 'pastore'
  spec.version = Pastore::VERSION
  spec.authors = ['Groza Sergiu']
  spec.email = ['developers@opinioni.net']

  spec.summary = <<~DESC
    A powerful gem for Rails that simplifies the process of validating parameters and controlling access to actions in your controllers.
  DESC

  spec.description = <<~DESC
    Pastore is a powerful gem for Rails that simplifies the process of
    validating parameters and controlling access to actions in your controllers.
    With Pastore, you can easily define validations for your parameters,
    ensuring that they meet specific requirements before being passed to your controller actions.
    Additionally, Pastore allows you to easily control access to your actions,
    ensuring that only authorized users can access sensitive information.
    With its intuitive interface and robust features,
    Pastore is a must-have tool for any Rails developer looking to improve
    the security and reliability of their application.
  DESC
  spec.homepage = 'https://github.com/demetra-it/pastore'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_runtime_dependency 'rails', '>= 4.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
