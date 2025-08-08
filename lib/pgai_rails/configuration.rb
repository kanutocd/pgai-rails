# frozen_string_literal: true

module PgaiRails
  class Configuration
    attr_accessor :ollama_base_url, :default_provider, :default_model, :default_dimensions,
                  :auto_vectorize, :fallback_on_error, :provider_configs

    def initialize
      @ollama_base_url = 'http://localhost:11434'
      @default_provider = :ollama
      @default_model = 'nomic-embed-text'
      @default_dimensions = 768
      @auto_vectorize = true
      @fallback_on_error = true
      @provider_configs = {}
    end

    def configure_provider(provider, **options)
      @provider_configs[provider] = options
    end

    def provider_config(provider)
      @provider_configs[provider] || {}
    end
  end
end
