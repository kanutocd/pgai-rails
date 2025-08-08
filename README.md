# pgai_rails

Rails integration for TimescaleDB's pgai PostgreSQL extension.

**⚠️ This gem is in early development and not yet ready for production use.**

## About

pgai_rails provides Rails-native integration with TimescaleDB's pgai extension, making AI-powered vectorization and semantic search simple and intuitive in Rails applications.

Transform complex pgai SQL operations into familiar Rails patterns:

```ruby
# Instead of complex SQL vectorizer setup
class Post < ApplicationRecord
  include PgaiRails::Vectorizable
  
  vectorize :content, provider: :ollama, model: 'nomic-embed-text'
end

# Simple semantic search
Post.semantic_search("machine learning")
```

## Supported Providers

pgai_rails supports all major embedding providers that pgai supports:

### Direct Providers
- **Ollama** - Local and hosted Ollama models
- **OpenAI** - text-embedding-3-small, text-embedding-ada-002, etc.
- **Voyage AI** - voyage-2, voyage-code-2, etc.

### LiteLLM Providers  
- **Cohere** - embed-english-v3.0, etc.
- **Mistral** - mistral-embed, etc.
- **Azure OpenAI** - Azure-hosted OpenAI models
- **Hugging Face** - Any embedding model from HF
- **AWS Bedrock** - Amazon Titan and other Bedrock models
- **Google Vertex AI** - textembedding-gecko, etc.

## Usage Examples

### Migration DSL

```ruby
# Create vectorizer for different providers
class CreatePostVectorizer < ActiveRecord::Migration[7.1]
  def up
    # Ollama (default)
    create_vectorizer 'posts' do
      loading_column 'content'
      embedding :ollama, model: 'nomic-embed-text', dimensions: 768
      chunking :character, size: 512, overlap: 50
    end

    # OpenAI
    create_vectorizer 'articles', name: 'articles_openai' do
      loading_column 'body'
      embedding :openai, model: 'text-embedding-3-small', dimensions: 1536
      chunking :recursive, size: 1000, overlap: 100
    end

    # Cohere via LiteLLM
    create_vectorizer 'documents', name: 'docs_cohere' do
      loading_column 'text'
      embedding :cohere, 
                model: 'embed-english-v3.0', 
                dimensions: 1024,
                api_key_name: 'COHERE_API_KEY'
    end
  end

  def down
    drop_vectorizer 'posts_vectorizer'
    drop_vectorizer 'articles_openai'  
    drop_vectorizer 'docs_cohere'
  end
end
```

## Installation

Add to your Gemfile:

```ruby
gem 'pgai_rails'
```

## Requirements

- Ruby >= 3.2.0  
- Rails >= 7.1 (ActiveRecord, ActiveSupport, Railties)
- PostgreSQL with pgai extension installed
- TimescaleDB (optional but recommended)

### Configuration

```ruby
# config/initializers/pgai_rails.rb
PgaiRails.configure do |config|
  config.default_provider = :ollama
  config.ollama_base_url = 'http://localhost:11434'
  config.default_model = 'nomic-embed-text'
  config.default_dimensions = 768
  config.fallback_on_error = true

  # Configure provider-specific settings
  config.configure_provider :openai, api_key: ENV['OPENAI_API_KEY']
  config.configure_provider :cohere, api_key: ENV['COHERE_API_KEY']
end
```

### Provider-Specific Examples

```ruby
# Ollama with custom parameters
embedding :ollama, 
          model: 'nomic-embed-text', 
          dimensions: 768,
          base_url: 'http://custom-ollama:11434',
          model_parameters: 'temperature:0.1',
          keep_alive: '5m'

# OpenAI with automatic dimensions
embedding :openai, model: 'text-embedding-3-small' # dimensions auto-detected

# Cohere with search optimization  
embedding :cohere, 
          model: 'embed-english-v3.0',
          dimensions: 1024,
          input_type: 'search_document',
          api_key_name: 'COHERE_API_KEY'

# Azure OpenAI
embedding :azure_openai,
          model: 'text-embedding-ada-002',
          api_key_name: 'AZURE_OPENAI_KEY'

# Hugging Face model
embedding :huggingface,
          model: 'microsoft/codebert-base',
          dimensions: 768

# AWS Bedrock  
embedding :aws_bedrock,
          model: 'amazon.titan-embed-text-v1',
          dimensions: 1536
```

## Rails Integration

pgai_rails provides convenient Rake tasks for Rails applications:

### Generate Initializer

```bash
rails pgai_rails:init
```

Creates `config/initializers/pgai_rails.rb` with comprehensive configuration options for all supported providers.

### Check System Status

```bash
rails pgai_rails:status
```

Displays:
- pgai and pgvector extension availability
- Current configuration settings
- Active vectorizers in your database

### List Providers

```bash
rails pgai_rails:providers
```

Shows all supported embedding providers with usage examples.

### Reset Extension Cache

```bash  
rails pgai_rails:reset_cache
```

Clears cached extension detection results.

## Status

This gem is under active development. **Phase 1 (Foundation)** and **Phase 2 (Migration Helpers)** are complete with comprehensive provider support and Rails integration.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/pgai_rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/pgai_rails/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PgaiRails project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/pgai_rails/blob/main/CODE_OF_CONDUCT.md).
