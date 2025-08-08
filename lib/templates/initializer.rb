# frozen_string_literal: true

# PgaiRails Configuration
#
# This initializer configures pgai_rails for AI-powered vectorization and semantic search.
# pgai_rails provides Rails-native integration with TimescaleDB's pgai PostgreSQL extension.

PgaiRails.configure do |config|
  # Default embedding provider (:ollama, :openai, :voyageai, :cohere, :mistral, etc.)
  config.default_provider = :ollama

  # Default model and dimensions
  config.default_model = 'nomic-embed-text'
  config.default_dimensions = 768

  # Ollama configuration
  config.ollama_base_url = ENV.fetch('OLLAMA_BASE_URL', 'http://localhost:11434')

  # Automatic vectorization settings
  config.auto_vectorize = true
  config.fallback_on_error = true

  # Provider-specific configurations
  # Uncomment and configure the providers you plan to use:

  # OpenAI
  # config.configure_provider :openai,
  #   api_key: ENV['OPENAI_API_KEY']

  # Cohere
  # config.configure_provider :cohere,
  #   api_key: ENV['COHERE_API_KEY']

  # Mistral
  # config.configure_provider :mistral,
  #   api_key: ENV['MISTRAL_API_KEY']

  # Voyage AI
  # config.configure_provider :voyageai,
  #   api_key: ENV['VOYAGE_API_KEY']

  # Azure OpenAI
  # config.configure_provider :azure_openai,
  #   api_key: ENV['AZURE_OPENAI_API_KEY'],
  #   base_url: ENV['AZURE_OPENAI_BASE_URL']

  # AWS Bedrock (requires AWS credentials configured separately)
  # config.configure_provider :aws_bedrock,
  #   region: ENV['AWS_REGION']

  # Google Vertex AI (requires GCP credentials configured separately)
  # config.configure_provider :vertex_ai,
  #   project_id: ENV['GOOGLE_CLOUD_PROJECT'],
  #   region: ENV['GOOGLE_CLOUD_REGION']

  # Hugging Face
  # config.configure_provider :huggingface,
  #   api_key: ENV['HUGGINGFACE_API_KEY']
end

# Environment Variables Reference:
#
# Required for non-Ollama providers:
# - OPENAI_API_KEY      - OpenAI API key
# - COHERE_API_KEY      - Cohere API key
# - MISTRAL_API_KEY     - Mistral API key
# - VOYAGE_API_KEY      - Voyage AI API key
# - HUGGINGFACE_API_KEY - Hugging Face API key
#
# Azure OpenAI:
# - AZURE_OPENAI_API_KEY - Azure OpenAI API key
# - AZURE_OPENAI_BASE_URL - Azure OpenAI endpoint URL
#
# AWS Bedrock (use standard AWS environment variables):
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - AWS_REGION
#
# Google Vertex AI (use standard GCP environment variables):
# - GOOGLE_APPLICATION_CREDENTIALS - Path to service account JSON
# - GOOGLE_CLOUD_PROJECT
# - GOOGLE_CLOUD_REGION
#
# Optional:
# - OLLAMA_BASE_URL     - Ollama server URL (default: http://localhost:11434)

# Example vectorizer creation in migration:
#
# class CreatePostVectorizer < ActiveRecord::Migration[7.1]
#   def up
#     create_vectorizer 'posts' do
#       loading_column 'content'
#       embedding :ollama, model: 'nomic-embed-text', dimensions: 768
#       chunking :character, size: 512, overlap: 50
#       formatting 'Title: $title Body: $chunk'
#     end
#   end
#
#   def down
#     drop_vectorizer 'posts_vectorizer'
#   end
# end

# Example model integration (coming in Phase 3):
#
# class Post < ApplicationRecord
#   include PgaiRails::Vectorizable
#
#   vectorize :content, provider: :ollama, model: 'nomic-embed-text'
#
#   # This will enable:
#   # Post.semantic_search("machine learning")
#   # post.similar_records(limit: 5)
# end
