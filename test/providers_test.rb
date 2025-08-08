# frozen_string_literal: true

require 'test_helper'
require 'active_support/testing/assertions'

class ProviderTest < Minitest::Test
  include ActiveSupport::Testing::Assertions

  def setup
    # Ensure we have a clean state
    @expected_direct_providers = [:ollama, :openai, :voyageai]
    @expected_litellm_providers = [:litellm, :cohere, :mistral, :azure_openai, :huggingface, :aws_bedrock, :vertex_ai]
    @all_expected_providers = @expected_direct_providers + @expected_litellm_providers
  end

  context 'SUPPORTED_PROVIDERS constant' do
    should 'be frozen and immutable' do
      assert_predicate PgaiRails::SUPPORTED_PROVIDERS, :frozen?

      # Should not allow modification
      assert_raises(FrozenError) do
        PgaiRails::SUPPORTED_PROVIDERS[:new_provider] = {}
      end
    end

    should 'contain all expected providers' do
      actual_providers = PgaiRails::SUPPORTED_PROVIDERS.keys.sort
      expected_providers = @all_expected_providers.sort

      assert_equal expected_providers, actual_providers
    end

    should 'have consistent structure for all providers' do
      PgaiRails::SUPPORTED_PROVIDERS.each do |provider, config|
        # Required keys
        assert config.key?(:type), "#{provider} missing :type"
        assert config.key?(:pgai_function), "#{provider} missing :pgai_function"
        assert config.key?(:description), "#{provider} missing :description"
        assert config.key?(:features), "#{provider} missing :features"
        assert config.key?(:default_dimensions), "#{provider} missing :default_dimensions"
        assert config.key?(:common_models), "#{provider} missing :common_models"
        assert config.key?(:documentation_url), "#{provider} missing :documentation_url"
        assert config.key?(:self_hosted), "#{provider} missing :self_hosted"

        # Type validation
        assert_includes [:direct, :litellm], config[:type], "#{provider} has invalid type"

        # Features should be an array
        assert_kind_of Array, config[:features], "#{provider} features should be array"

        # Default dimensions should be positive integer
        assert_kind_of Integer, config[:default_dimensions], "#{provider} default_dimensions should be integer"
        assert_operator config[:default_dimensions], :>, 0, "#{provider} default_dimensions should be positive"

        # Common models should be a hash
        assert_kind_of Hash, config[:common_models], "#{provider} common_models should be hash"

        # Documentation URL should be a string
        assert_kind_of String, config[:documentation_url], "#{provider} documentation_url should be string"
        assert_match(%r{\Ahttps?://}, config[:documentation_url], "#{provider} should have valid URL")

        # Self hosted should be boolean
        assert_includes [true, false], config[:self_hosted], "#{provider} self_hosted should be boolean"
      end
    end

    should 'have correct provider types' do
      # Direct providers
      @expected_direct_providers.each do |provider|
        config = PgaiRails::SUPPORTED_PROVIDERS[provider]

        assert_equal :direct, config[:type], "#{provider} should be direct type"
        assert_match(/^ai\.embedding_/, config[:pgai_function], "#{provider} should have direct pgai function")
      end

      # LiteLLM providers (except direct litellm)
      (@expected_litellm_providers - [:litellm]).each do |provider|
        config = PgaiRails::SUPPORTED_PROVIDERS[provider]

        assert_equal :litellm, config[:type], "#{provider} should be litellm type"
        assert_equal 'ai.embedding_litellm', config[:pgai_function], "#{provider} should use litellm function"
        assert config.key?(:litellm_prefix), "#{provider} should have litellm_prefix"
      end

      # Direct litellm usage
      litellm_config = PgaiRails::SUPPORTED_PROVIDERS[:litellm]

      assert_equal :litellm, litellm_config[:type]
      assert_equal 'ai.embedding_litellm', litellm_config[:pgai_function]
      assert_not litellm_config.key?(:litellm_prefix), 'Direct litellm should not have prefix'
    end

    should 'have valid common models with dimensions' do
      PgaiRails::SUPPORTED_PROVIDERS.each do |provider, config|
        config[:common_models].each do |model, model_config|
          assert_kind_of String, model, "#{provider} model name should be string"
          assert_kind_of Hash, model_config, "#{provider} model config should be hash"

          if model_config.key?(:dimensions)
            assert_kind_of Integer, model_config[:dimensions], "#{provider} model #{model} dimensions should be integer"
            assert_operator model_config[:dimensions], :>, 0, "#{provider} model #{model} dimensions should be positive"
          end
        end
      end
    end
  end

  context 'Provider module' do
    should 'return all provider names' do
      all_providers = PgaiRails::Provider.all

      assert_kind_of Array, all_providers
      assert_equal @all_expected_providers.sort, all_providers.sort
    end

    should 'return direct providers only' do
      direct_providers = PgaiRails::Provider.direct_providers

      assert_kind_of Array, direct_providers
      assert_equal @expected_direct_providers.sort, direct_providers.sort
    end

    should 'return litellm providers only' do
      litellm_providers = PgaiRails::Provider.litellm_providers

      assert_kind_of Array, litellm_providers
      assert_equal @expected_litellm_providers.sort, litellm_providers.sort
    end

    should 'return provider configuration' do
      config = PgaiRails::Provider.config_for(:ollama)

      assert_kind_of Hash, config
      assert_equal :direct, config[:type]
      assert_equal 'ai.embedding_ollama', config[:pgai_function]
      assert_equal 'Local and hosted Ollama models', config[:description]
    end

    should 'return nil for unknown provider' do
      config = PgaiRails::Provider.config_for(:unknown_provider)

      assert_nil config
    end

    should 'handle string provider names' do
      config = PgaiRails::Provider.config_for('ollama')

      assert_kind_of Hash, config
      assert_equal :direct, config[:type]
    end

    should 'check if provider is supported' do
      # Known providers
      assert PgaiRails::Provider.supported?(:ollama)
      assert PgaiRails::Provider.supported?(:openai)
      assert PgaiRails::Provider.supported?(:cohere)
      assert PgaiRails::Provider.supported?('ollama')

      # Unknown provider
      assert_not PgaiRails::Provider.supported?(:unknown_provider)
      assert_not PgaiRails::Provider.supported?('unknown_provider')
      assert_not PgaiRails::Provider.supported?(nil)
    end

    should 'return provider type' do
      assert_equal :direct, PgaiRails::Provider.type_of(:ollama)
      assert_equal :direct, PgaiRails::Provider.type_of(:openai)
      assert_equal :litellm, PgaiRails::Provider.type_of(:cohere)
      assert_equal :litellm, PgaiRails::Provider.type_of(:litellm)
      assert_nil PgaiRails::Provider.type_of(:unknown_provider)
    end

    should 'check if provider is direct' do
      assert PgaiRails::Provider.direct?(:ollama)
      assert PgaiRails::Provider.direct?(:openai)
      assert PgaiRails::Provider.direct?(:voyageai)

      assert_not PgaiRails::Provider.direct?(:cohere)
      assert_not PgaiRails::Provider.direct?(:litellm)
      assert_not PgaiRails::Provider.direct?(:unknown_provider)
    end

    should 'check if provider is litellm' do
      assert PgaiRails::Provider.litellm?(:cohere)
      assert PgaiRails::Provider.litellm?(:mistral)
      assert PgaiRails::Provider.litellm?(:litellm)

      assert_not PgaiRails::Provider.litellm?(:ollama)
      assert_not PgaiRails::Provider.litellm?(:openai)
      assert_not PgaiRails::Provider.litellm?(:unknown_provider)
    end

    should 'return providers requiring API keys' do
      api_key_providers = PgaiRails::Provider.requiring_api_keys

      assert_kind_of Array, api_key_providers
      assert_includes api_key_providers, :openai
      assert_includes api_key_providers, :cohere
      assert_includes api_key_providers, :mistral
      assert_not_includes api_key_providers, :ollama # Self-hosted, no API key required
    end

    should 'return self-hosted providers' do
      self_hosted_providers = PgaiRails::Provider.self_hosted

      assert_kind_of Array, self_hosted_providers
      assert_includes self_hosted_providers, :ollama
      assert_not_includes self_hosted_providers, :openai
    end

    should 'return providers with specific features' do
      custom_base_url_providers = PgaiRails::Provider.with_feature(:custom_base_url)

      assert_includes custom_base_url_providers, :ollama

      api_key_name_providers = PgaiRails::Provider.with_feature(:api_key_name)

      assert_includes api_key_name_providers, :openai
      assert_includes api_key_name_providers, :cohere

      auto_prefix_providers = PgaiRails::Provider.with_feature(:auto_prefix)

      assert_includes auto_prefix_providers, :cohere
      assert_includes auto_prefix_providers, :mistral
    end

    should 'return provider pgai function name' do
      assert_equal 'ai.embedding_ollama', PgaiRails::Provider.pgai_function_for(:ollama)
      assert_equal 'ai.embedding_openai', PgaiRails::Provider.pgai_function_for(:openai)
      assert_equal 'ai.embedding_litellm', PgaiRails::Provider.pgai_function_for(:cohere)
      assert_nil PgaiRails::Provider.pgai_function_for(:unknown_provider)
    end

    should 'return provider litellm prefix' do
      assert_equal 'cohere', PgaiRails::Provider.litellm_prefix_for(:cohere)
      assert_equal 'mistral', PgaiRails::Provider.litellm_prefix_for(:mistral)
      assert_equal 'azure', PgaiRails::Provider.litellm_prefix_for(:azure_openai)
      assert_nil PgaiRails::Provider.litellm_prefix_for(:ollama) # Direct provider
      assert_nil PgaiRails::Provider.litellm_prefix_for(:litellm) # No prefix for direct litellm
    end

    should 'return default dimensions for provider' do
      assert_equal 768, PgaiRails::Provider.default_dimensions_for(:ollama)
      assert_equal 1536, PgaiRails::Provider.default_dimensions_for(:openai)
      assert_equal 1024, PgaiRails::Provider.default_dimensions_for(:cohere)
      assert_nil PgaiRails::Provider.default_dimensions_for(:unknown_provider)
    end

    should 'return common models for provider' do
      ollama_models = PgaiRails::Provider.common_models_for(:ollama)

      assert_kind_of Hash, ollama_models
      assert_includes ollama_models, 'nomic-embed-text'
      assert_includes ollama_models, 'mxbai-embed-large'

      openai_models = PgaiRails::Provider.common_models_for(:openai)

      assert_kind_of Hash, openai_models
      assert_includes openai_models, 'text-embedding-3-small'
      assert_includes openai_models, 'text-embedding-3-large'

      # Unknown provider
      unknown_models = PgaiRails::Provider.common_models_for(:unknown_provider)

      assert_empty(unknown_models)
    end

    should 'return model dimensions for specific model' do
      # Ollama models
      assert_equal 768, PgaiRails::Provider.dimensions_for_model(:ollama, 'nomic-embed-text')
      assert_equal 1024, PgaiRails::Provider.dimensions_for_model(:ollama, 'mxbai-embed-large')
      assert_equal 384, PgaiRails::Provider.dimensions_for_model(:ollama, 'all-minilm')

      # OpenAI models
      assert_equal 1536, PgaiRails::Provider.dimensions_for_model(:openai, 'text-embedding-3-small')
      assert_equal 3072, PgaiRails::Provider.dimensions_for_model(:openai, 'text-embedding-3-large')
      assert_equal 1536, PgaiRails::Provider.dimensions_for_model(:openai, 'text-embedding-ada-002')

      # Unknown model (should return provider default)
      assert_equal 768, PgaiRails::Provider.dimensions_for_model(:ollama, 'unknown-model')
      assert_equal 1536, PgaiRails::Provider.dimensions_for_model(:openai, 'unknown-model')

      # Unknown provider (should return nil)
      assert_nil PgaiRails::Provider.dimensions_for_model(:unknown_provider, 'any-model')
    end

    should 'handle edge cases gracefully' do
      # Nil inputs
      assert_nil PgaiRails::Provider.config_for(nil)
      assert_not PgaiRails::Provider.supported?(nil)
      assert_nil PgaiRails::Provider.type_of(nil)
      assert_not PgaiRails::Provider.direct?(nil)
      assert_not PgaiRails::Provider.litellm?(nil)

      # Empty strings
      assert_nil PgaiRails::Provider.config_for('')
      assert_not PgaiRails::Provider.supported?('')

      # Symbol vs string consistency
      assert_equal PgaiRails::Provider.config_for(:ollama), PgaiRails::Provider.config_for('ollama')
      assert_equal PgaiRails::Provider.supported?(:ollama), PgaiRails::Provider.supported?('ollama')
    end
  end

  context 'Provider-specific configurations' do
    should 'have correct Ollama configuration' do
      config = PgaiRails::Provider.config_for(:ollama)

      assert_equal :direct, config[:type]
      assert_equal 'ai.embedding_ollama', config[:pgai_function]
      assert_includes config[:features], :custom_base_url
      assert_includes config[:features], :model_parameters
      assert_includes config[:features], :keep_alive
      assert_not config[:api_key_required]
      assert config[:self_hosted]
    end

    should 'have correct OpenAI configuration' do
      config = PgaiRails::Provider.config_for(:openai)

      assert_equal :direct, config[:type]
      assert_equal 'ai.embedding_openai', config[:pgai_function]
      assert_includes config[:features], :api_key_name
      assert config[:api_key_required]
      assert_equal 'OPENAI_API_KEY', config[:api_key_env_var]
      assert_not config[:self_hosted]
    end

    should 'have correct Cohere configuration' do
      config = PgaiRails::Provider.config_for(:cohere)

      assert_equal :litellm, config[:type]
      assert_equal 'ai.embedding_litellm', config[:pgai_function]
      assert_equal 'cohere', config[:litellm_prefix]
      assert_includes config[:features], :input_type
      assert config[:api_key_required]
      assert_equal 'COHERE_API_KEY', config[:api_key_env_var]
      assert_includes config[:unique_features],
                      'Input type optimization (search_document, search_query, classification)'
    end

    should 'have correct AWS Bedrock configuration' do
      config = PgaiRails::Provider.config_for(:aws_bedrock)

      assert_equal :litellm, config[:type]
      assert_equal 'bedrock', config[:litellm_prefix]
      assert_includes config[:features], :aws_credentials
      assert_not config[:api_key_required]
      assert config[:aws_credentials_required]
      assert_includes config[:aws_env_vars], 'AWS_ACCESS_KEY_ID'
      assert_includes config[:aws_env_vars], 'AWS_SECRET_ACCESS_KEY'
      assert_includes config[:aws_env_vars], 'AWS_REGION'
    end

    should 'have correct Vertex AI configuration' do
      config = PgaiRails::Provider.config_for(:vertex_ai)

      assert_equal :litellm, config[:type]
      assert_equal 'vertex_ai', config[:litellm_prefix]
      assert_includes config[:features], :gcp_credentials
      assert_not config[:api_key_required]
      assert config[:gcp_credentials_required]
      assert_includes config[:gcp_env_vars], 'GOOGLE_APPLICATION_CREDENTIALS'
      assert_includes config[:gcp_env_vars], 'GOOGLE_CLOUD_PROJECT'
    end
  end

  context 'Integration with other components' do
    should 'work with VectorizerBuilder validation' do
      # This tests the integration between Provider module and VectorizerBuilder
      builder = PgaiRails::VectorizerBuilder.new('test_table', 'test_vectorizer')

      # Should not raise error for supported providers
      assert_nothing_raised do
        builder.embedding(:ollama, model: 'test-model')
      end

      assert_nothing_raised do
        builder.embedding(:cohere, model: 'embed-english-v3.0')
      end

      # Should raise error for unsupported providers
      assert_raises(ArgumentError, /Unsupported provider/) do
        builder.embedding(:unknown_provider, model: 'test-model')
      end
    end

    should 'provide consistent provider lists' do
      # Ensure that all methods return consistent results
      all_from_constant = PgaiRails::SUPPORTED_PROVIDERS.keys.sort
      all_from_method = PgaiRails::Provider.all.sort

      assert_equal all_from_constant, all_from_method

      # Direct + LiteLLM should equal all
      direct = PgaiRails::Provider.direct_providers
      litellm = PgaiRails::Provider.litellm_providers
      combined = (direct + litellm).sort

      assert_equal all_from_method, combined
    end
  end
end
