# frozen_string_literal: true

require_relative "lib/pgai_rails/version"

Gem::Specification.new do |spec|
  spec.name = "pgai_rails"
  spec.version = PgaiRails::VERSION
  spec.authors = ["Ken C. Demanawa"]
  spec.email = ["kenneth.c.demanawa@gmail.com"]

  spec.summary = "Ruby on Rails integration for TimescaleDB's pgai PostgreSQL extension."
  spec.description = "Provides Rails-native integration with TimescaleDB's pgai extension, making AI-powered vectorization and semantic search simple and intuitive in Rails applications."

  spec.homepage = "https://github.com/kanutocd/pgai_rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "pg", "~> 1.6"

  spec.add_development_dependency "irb", "~> 1.15"
  spec.add_development_dependency "rake", "~> 13.3"
  spec.add_development_dependency "rubocop", "~> 1.79"
  spec.add_development_dependency "rubocop-rake", "~> 0.7.1"
  spec.add_development_dependency "yard", "~> 0.9.37"
  spec.add_development_dependency "rubocop-performance", "~> 1.25"
  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "rubocop-rails", "~> 2.32"
  spec.add_development_dependency "rubocop-minitest", "~> 0.38.1"

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
