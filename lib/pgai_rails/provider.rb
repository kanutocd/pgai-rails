# frozen_string_literal: true

module PgaiRails
  # Comprehensive registry of all supported embedding providers with metadata
  SUPPORTED_PROVIDERS = {
    # Direct Provider - Native pgai integration
    ollama: {
      type: :direct,
      pgai_function: 'ai.embedding_ollama',
      description: 'Local and hosted Ollama models',
      features: [:custom_base_url, :model_parameters, :keep_alive],
      default_dimensions: 768,
      common_models: {
        'nomic-embed-text' => { dimensions: 768 },
        'mxbai-embed-large' => { dimensions: 1024 },
        'all-minilm' => { dimensions: 384 },
      },
      documentation_url: 'https://github.com/ollama/ollama',
      api_key_required: false,
      self_hosted: true,
    },

    openai: {
      type: :direct,
      pgai_function: 'ai.embedding_openai',
      description: 'OpenAI embedding models',
      features: [:api_key_name, :auto_dimensions],
      default_dimensions: 1536,
      common_models: {
        'text-embedding-3-small' => { dimensions: 1536 },
        'text-embedding-3-large' => { dimensions: 3072 },
        'text-embedding-ada-002' => { dimensions: 1536 },
      },
      documentation_url: 'https://platform.openai.com/docs/guides/embeddings',
      api_key_required: true,
      api_key_env_var: 'OPENAI_API_KEY',
      self_hosted: false,
    },

    voyageai: {
      type: :direct,
      pgai_function: 'ai.embedding_voyageai',
      description: 'Voyage AI specialized embedding models',
      features: [:api_key_name, :auto_dimensions],
      default_dimensions: 1024,
      common_models: {
        'voyage-2' => { dimensions: 1024 },
        'voyage-code-2' => { dimensions: 1536 },
        'voyage-large-2' => { dimensions: 1536 },
      },
      documentation_url: 'https://docs.voyageai.com/',
      api_key_required: true,
      api_key_env_var: 'VOYAGE_API_KEY',
      self_hosted: false,
    },

    # LiteLLM Provider - Via LiteLLM integration
    litellm: {
      type: :litellm,
      pgai_function: 'ai.embedding_litellm',
      description: 'Direct LiteLLM integration with full model string',
      features: [:api_key_name, :provider_specific_params],
      default_dimensions: 768,
      common_models: {
        'cohere/embed-english-v3.0' => { dimensions: 1024 },
        'mistral/mistral-embed' => { dimensions: 1024 },
        'azure/text-embedding-ada-002' => { dimensions: 1536 },
      },
      documentation_url: 'https://docs.litellm.ai/docs/embedding/supported_embedding',
      api_key_required: true,
      self_hosted: false,
    },

    cohere: {
      type: :litellm,
      pgai_function: 'ai.embedding_litellm',
      litellm_prefix: 'cohere',
      description: 'Cohere embedding models with search optimization',
      features: [:api_key_name, :input_type, :auto_prefix],
      default_dimensions: 1024,
      common_models: {
        'embed-english-v3.0' => { dimensions: 1024 },
        'embed-multilingual-v3.0' => { dimensions: 1024 },
        'embed-english-light-v3.0' => { dimensions: 384 },
      },
      documentation_url: 'https://docs.cohere.com/docs/embeddings',
      api_key_required: true,
      api_key_env_var: 'COHERE_API_KEY',
      self_hosted: false,
      unique_features: ['Input type optimization (search_document, search_query, classification)'],
    },

    mistral: {
      type: :litellm,
      pgai_function: 'ai.embedding_litellm',
      litellm_prefix: 'mistral',
      description: 'Mistral embedding models',
      features: [:api_key_name, :auto_prefix],
      default_dimensions: 1024,
      common_models: {
        'mistral-embed' => { dimensions: 1024 },
      },
      documentation_url: 'https://docs.mistral.ai/capabilities/embeddings/',
      api_key_required: true,
      api_key_env_var: 'MISTRAL_API_KEY',
      self_hosted: false,
    },

    azure_openai: {
      type: :litellm,
      pgai_function: 'ai.embedding_litellm',
      litellm_prefix: 'azure',
      description: 'Azure-hosted OpenAI embedding models',
      features: [:api_key_name, :base_url, :auto_prefix],
      default_dimensions: 1536,
      common_models: {
        'text-embedding-ada-002' => { dimensions: 1536 },
        'text-embedding-3-small' => { dimensions: 1536 },
        'text-embedding-3-large' => { dimensions: 3072 },
      },
      documentation_url: 'https://learn.microsoft.com/en-us/azure/ai-services/openai/',
      api_key_required: true,
      api_key_env_var: 'AZURE_OPENAI_API_KEY',
      self_hosted: false,
      unique_features: ['Enterprise Azure integration', 'Custom deployment names'],
    },

    huggingface: {
      type: :litellm,
      pgai_function: 'ai.embedding_litellm',
      litellm_prefix: 'huggingface',
      description: 'Hugging Face embedding models via Inference API',
      features: [:api_key_name, :auto_prefix],
      default_dimensions: 768,
      common_models: {
        'sentence-transformers/all-MiniLM-L6-v2' => { dimensions: 384 },
        'sentence-transformers/all-mpnet-base-v2' => { dimensions: 768 },
        'microsoft/codebert-base' => { dimensions: 768 },
      },
      documentation_url: 'https://huggingface.co/docs/api-inference/detailed_parameters#feature-extraction-task',
      api_key_required: true,
      api_key_env_var: 'HUGGINGFACE_API_KEY',
      self_hosted: false,
      unique_features: ['Access to thousands of open-source models'],
    },

    aws_bedrock: {
      type: :litellm,
      pgai_function: 'ai.embedding_litellm',
      litellm_prefix: 'bedrock',
      description: 'Amazon Bedrock embedding models',
      features: [:aws_credentials, :auto_prefix],
      default_dimensions: 1536,
      common_models: {
        'amazon.titan-embed-text-v1' => { dimensions: 1536 },
        'cohere.embed-english-v3' => { dimensions: 1024 },
        'cohere.embed-multilingual-v3' => { dimensions: 1024 },
      },
      documentation_url: 'https://docs.aws.amazon.com/bedrock/latest/userguide/what-is-bedrock.html',
      api_key_required: false,
      aws_credentials_required: true,
      aws_env_vars: ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_REGION'],
      self_hosted: false,
      unique_features: ['AWS IAM integration', 'Enterprise compliance'],
    },

    vertex_ai: {
      type: :litellm,
      pgai_function: 'ai.embedding_litellm',
      litellm_prefix: 'vertex_ai',
      description: 'Google Vertex AI embedding models',
      features: [:gcp_credentials, :auto_prefix],
      default_dimensions: 768,
      common_models: {
        'textembedding-gecko@003' => { dimensions: 768 },
        'textembedding-gecko@001' => { dimensions: 768 },
        'textembedding-gecko-multilingual@001' => { dimensions: 768 },
      },
      documentation_url: 'https://cloud.google.com/vertex-ai/docs/generative-ai/embeddings/get-text-embeddings',
      api_key_required: false,
      gcp_credentials_required: true,
      gcp_env_vars: ['GOOGLE_APPLICATION_CREDENTIALS', 'GOOGLE_CLOUD_PROJECT', 'GOOGLE_CLOUD_REGION'],
      self_hosted: false,
      unique_features: ['GCP IAM integration', 'Multilingual support'],
    },
  }.freeze

  # Helper methods for provider introspection
  module Provider
    class << self
      # Get all provider names
      def all
        SUPPORTED_PROVIDERS.keys
      end

      # Get providers by type
      def direct_providers
        SUPPORTED_PROVIDERS.select { |_, config| config[:type] == :direct }.keys
      end

      def litellm_providers
        SUPPORTED_PROVIDERS.select { |_, config| config[:type] == :litellm }.keys
      end

      # Get provider configuration
      def config_for(provider)
        SUPPORTED_PROVIDERS[provider&.to_sym]
      end

      # Check if provider is supported
      def supported?(provider)
        SUPPORTED_PROVIDERS.key?(provider&.to_sym)
      end

      # Get provider type
      def type_of(provider)
        config = config_for(provider)
        config&.dig(:type)
      end

      # Check if provider is direct
      def direct?(provider)
        type_of(provider) == :direct
      end

      # Check if provider is litellm
      def litellm?(provider)
        type_of(provider) == :litellm
      end

      # Get providers that require API keys
      def requiring_api_keys
        SUPPORTED_PROVIDERS.select { |_, config| config[:api_key_required] }.keys
      end

      # Get self-hosted providers
      def self_hosted
        SUPPORTED_PROVIDERS.select { |_, config| config[:self_hosted] }.keys
      end

      # Get providers with specific features
      def with_feature(feature)
        SUPPORTED_PROVIDERS.select { |_, config| config[:features]&.include?(feature.to_sym) }.keys
      end

      # Get provider's pgai function name
      def pgai_function_for(provider)
        config = config_for(provider)
        config&.dig(:pgai_function)
      end

      # Get provider's LiteLLM prefix
      def litellm_prefix_for(provider)
        config = config_for(provider)
        config&.dig(:litellm_prefix)
      end

      # Get default dimensions for provider
      def default_dimensions_for(provider)
        config = config_for(provider)
        config&.dig(:default_dimensions)
      end

      # Get common models for provider
      def common_models_for(provider)
        config = config_for(provider)
        config&.dig(:common_models) || {}
      end

      # Get model dimensions for specific model
      def dimensions_for_model(provider, model)
        models = common_models_for(provider)
        models.dig(model, :dimensions) || default_dimensions_for(provider)
      end
    end
  end
end
