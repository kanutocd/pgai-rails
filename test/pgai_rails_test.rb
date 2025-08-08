# frozen_string_literal: true

require 'test_helper'

class PgaiRailsTest < Minitest::Test
  def test_that_it_has_a_version_number
    assert_not_nil ::PgaiRails::VERSION
  end

  def test_configuration_defaults
    config = PgaiRails::Configuration.new

    assert_equal 'http://localhost:11434', config.ollama_base_url
    assert_equal :ollama, config.default_provider
    assert_equal 'nomic-embed-text', config.default_model
    assert_equal 768, config.default_dimensions
    assert config.auto_vectorize
    assert config.fallback_on_error
    assert_empty(config.provider_configs)
  end

  def test_configure_block
    PgaiRails.configure do |config|
      config.ollama_base_url = 'http://test:12345'
      config.default_provider = :openai
      config.default_model = 'test-model'
    end

    assert_equal 'http://test:12345', PgaiRails.configuration.ollama_base_url
    assert_equal :openai, PgaiRails.configuration.default_provider
    assert_equal 'test-model', PgaiRails.configuration.default_model
  ensure
    # Reset configuration
    PgaiRails.instance_variable_set(:@configuration, nil)
  end

  def test_provider_configuration
    config = PgaiRails::Configuration.new

    config.configure_provider(:openai, api_key: 'test-key', timeout: 30)
    config.configure_provider(:cohere, api_key: 'cohere-key')

    assert_equal({ api_key: 'test-key', timeout: 30 }, config.provider_config(:openai))
    assert_equal({ api_key: 'cohere-key' }, config.provider_config(:cohere))
    assert_empty(config.provider_config(:nonexistent))
  end
end
