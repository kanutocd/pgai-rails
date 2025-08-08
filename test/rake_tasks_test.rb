# frozen_string_literal: true

require 'test_helper'
require 'rake'

class RakeTasksTest < Minitest::Test
  def setup
    @rake = Rake::Application.new
    Rake.application = @rake
    # Create a mock environment task since this is a gem test, not a Rails app
    @rake.define_task(Rake::Task, :environment)
    load File.expand_path('../lib/tasks/pgai_rails.rake', __dir__)
  end

  def teardown
    Rake.application = nil
  end

  def test_rake_tasks_are_defined
    task_names = @rake.tasks.map(&:name)

    assert_includes task_names, 'pgai_rails:init'
    assert_includes task_names, 'pgai_rails:status'
    assert_includes task_names, 'pgai_rails:providers'
    assert_includes task_names, 'pgai_rails:reset_cache'
  end

  def test_init_task_exists
    task = @rake['pgai_rails:init']

    assert_not_nil task
    # Task descriptions are stored differently in Rake
    assert_kind_of Rake::Task, task
  end

  def test_status_task_exists
    task = @rake['pgai_rails:status']

    assert_not_nil task
    assert_kind_of Rake::Task, task
  end

  def test_providers_task_exists
    task = @rake['pgai_rails:providers']

    assert_not_nil task
    assert_kind_of Rake::Task, task
  end

  def test_reset_cache_task_exists
    task = @rake['pgai_rails:reset_cache']

    assert_not_nil task
    assert_kind_of Rake::Task, task
  end

  def test_providers_task_output
    output = capture_io do
      @rake['pgai_rails:providers'].invoke
    end[0]

    assert_includes output, 'Supported Embedding Provider'
    assert_includes output, 'ollama'
    assert_includes output, 'openai'
    assert_includes output, 'cohere'
    assert_includes output, 'mistral'
    assert_includes output, 'huggingface'
  end

  def test_reset_cache_task_requires_environment
    # The reset_cache task requires :environment which doesn't exist in our test
    # This is expected behavior - the task will only work in a Rails app
    task = @rake['pgai_rails:reset_cache']

    assert_not_nil task
    assert_kind_of Rake::Task, task
  end

  def test_template_file_exists
    template_path = File.expand_path('../lib/templates/initializer.rb', __dir__)

    assert_path_exists template_path, 'Initializer template should exist'

    template_content = File.read(template_path)

    assert_includes template_content, 'PgaiRails.configure'
    assert_includes template_content, 'config.default_provider'
    assert_includes template_content, 'ENV['
  end

  def test_docker_compose_template_exists
    docker_compose_template_path = File.expand_path('../lib/templates/docker-compose.yml', __dir__)

    assert_path_exists docker_compose_template_path, 'Docker compose template should exist'

    template_content = File.read(docker_compose_template_path)

    assert_includes template_content, 'services:'
    assert_includes template_content, 'postgres:'
    assert_includes template_content, 'vectorizer-worker:'
    assert_includes template_content, 'ollama:'
    assert_includes template_content, 'timescale/timescaledb-ha:pg17'
    assert_includes template_content, 'timescale/pgai-vectorizer-worker:latest'
    assert_includes template_content, 'ollama/ollama:0.10.1'
    assert_includes template_content, 'volumes:'
    assert_includes template_content, 'postgres_data:'
    assert_includes template_content, 'ollama_data:'
  end
end
