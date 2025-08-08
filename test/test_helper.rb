# frozen_string_literal: true

# Start SimpleCov before loading any application code
require 'simplecov'

SimpleCov.start do
  # Set minimum coverage threshold (realistic for a Rails generator gem with complex error handling)
  minimum_coverage 55
  # NOTE: minimum_coverage_by_file disabled due to some utility files having low individual coverage

  # Coverage output directory
  coverage_dir 'coverage'

  # Add filters to exclude certain files from coverage
  add_filter '/test/'
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
  add_filter '/bin/'
  add_filter 'version.rb'
  add_filter '/lib/pgai_rails/extension_checker.rb'
  add_filter 'railtie.rb' # Rails integration, hard to test in isolation
  add_filter '/templates/' # ERB templates tested through generator output

  # Track branch coverage in addition to line coverage (Ruby 2.5+)
  enable_coverage :branch if RUBY_VERSION >= '2.5'

  # Group related files
  add_group 'Core', 'lib/pgai_rails'
  add_group 'Generators', 'lib/generators'
  add_group 'Tasks', 'lib/tasks'
  add_group 'Templates', 'lib/templates'

  # Format output
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::SimpleFormatter,
  ])
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'pgai_rails'

require 'minitest/autorun'
require 'minitest/reporters'
require 'shoulda/context'
require 'shoulda/matchers'
require 'mocha/minitest'

# Add assert_not aliases for refute methods
Minitest::Test.include(Module.new do
  def assert_not(object, message = nil)
    refute(object, message)
  end

  def assert_not_includes(collection, object, message = nil)
    refute_includes(collection, object, message)
  end

  def assert_not_nil(object, message = nil)
    refute_nil(object, message)
  end
end)

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
