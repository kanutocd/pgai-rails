# frozen_string_literal: true

require 'test_helper'

class VectorizerBuilderTest < Minitest::Test
  def setup
    @builder = PgaiRails::VectorizerBuilder.new('posts', 'test_vectorizer')
  end

  context 'initialization' do
    should 'set table name and vectorizer name' do
      assert_equal 'posts', @builder.table_name
      assert_equal 'test_vectorizer', @builder.name
    end
  end

  context '#loading_column' do
    should 'set loading configuration' do
      @builder.loading_column('content')
      sql = extract_option_from_sql(@builder, :loading)

      assert_equal "ai.loading_column('content')", sql
    end
  end

  context '#embedding' do
    should 'configure ollama embedding with default base_url' do
      @builder.embedding(:ollama, model: 'test-model', dimensions: 512)
      sql = extract_option_from_sql(@builder, :embedding)

      assert_equal "ai.embedding_ollama('test-model', 512, base_url => 'http://localhost:11434')", sql
    end

    should 'configure ollama embedding with custom base_url' do
      @builder.embedding(:ollama, model: 'test-model', dimensions: 512, base_url: 'http://custom:8080')
      sql = extract_option_from_sql(@builder, :embedding)

      assert_equal "ai.embedding_ollama('test-model', 512, base_url => 'http://custom:8080')", sql
    end

    should 'configure ollama embedding with optional parameters' do
      @builder.embedding(:ollama, model: 'test-model', dimensions: 512,
                                  model_parameters: 'temperature:0.5', keep_alive: '5m')
      sql = extract_option_from_sql(@builder, :embedding)
      expected = "ai.embedding_ollama('test-model', 512, base_url => 'http://localhost:11434', model_parameters => 'temperature:0.5', keep_alive => '5m')"

      assert_equal expected, sql
    end

    should 'configure openai embedding with default dimensions' do
      @builder.embedding(:openai, model: 'text-embedding-ada-002')
      sql = extract_option_from_sql(@builder, :embedding)

      assert_equal "ai.embedding_openai('text-embedding-ada-002', 1536)", sql
    end

    should 'configure openai embedding with custom dimensions and api key' do
      @builder.embedding(:openai, model: 'text-embedding-3-small', dimensions: 1536, api_key_name: 'MY_OPENAI_KEY')
      sql = extract_option_from_sql(@builder, :embedding)

      assert_equal "ai.embedding_openai('text-embedding-3-small', 1536, api_key_name => 'MY_OPENAI_KEY')", sql
    end

    should 'configure voyageai embedding' do
      @builder.embedding(:voyageai, model: 'voyage-2', dimensions: 1024)
      sql = extract_option_from_sql(@builder, :embedding)

      assert_equal "ai.embedding_voyageai('voyage-2', 1024)", sql
    end

    should 'configure voyageai embedding with api key' do
      @builder.embedding(:voyageai, model: 'voyage-code-2', api_key_name: 'VOYAGE_API_KEY')
      sql = extract_option_from_sql(@builder, :embedding)

      assert_equal "ai.embedding_voyageai('voyage-code-2', 1536, api_key_name => 'VOYAGE_API_KEY')", sql
    end

    should 'configure litellm embedding directly' do
      @builder.embedding(:litellm, model: 'cohere/embed-english-v3.0', dimensions: 1024)
      sql = extract_option_from_sql(@builder, :embedding)

      assert_equal "ai.embedding_litellm('cohere/embed-english-v3.0', 1024)", sql
    end

    should 'configure cohere embedding through litellm' do
      @builder.embedding(:cohere, model: 'embed-english-v3.0', dimensions: 1024, api_key_name: 'COHERE_API_KEY')
      sql = extract_option_from_sql(@builder, :embedding)

      assert_equal "ai.embedding_litellm('cohere/embed-english-v3.0', 1024, api_key_name => 'COHERE_API_KEY')", sql
    end

    should 'configure mistral embedding through litellm' do
      @builder.embedding(:mistral, model: 'mistral-embed', dimensions: 1024)
      sql = extract_option_from_sql(@builder, :embedding)

      assert_equal "ai.embedding_litellm('mistral/mistral-embed', 1024)", sql
    end

    should 'configure huggingface embedding through litellm' do
      @builder.embedding(:huggingface, model: 'microsoft/codebert-base', dimensions: 768)
      sql = extract_option_from_sql(@builder, :embedding)

      assert_equal "ai.embedding_litellm('huggingface/microsoft/codebert-base', 768)", sql
    end

    should 'configure azure_openai embedding through litellm' do
      @builder.embedding(:azure_openai, model: 'text-embedding-ada-002', dimensions: 1536,
                                        api_key_name: 'AZURE_API_KEY')
      sql = extract_option_from_sql(@builder, :embedding)

      assert_equal "ai.embedding_litellm('azure/text-embedding-ada-002', 1536, api_key_name => 'AZURE_API_KEY')", sql
    end

    should 'configure aws_bedrock embedding through litellm' do
      @builder.embedding(:aws_bedrock, model: 'amazon.titan-embed-text-v1', dimensions: 1536)
      sql = extract_option_from_sql(@builder, :embedding)

      assert_equal "ai.embedding_litellm('bedrock/amazon.titan-embed-text-v1', 1536)", sql
    end

    should 'configure vertex_ai embedding through litellm' do
      @builder.embedding(:vertex_ai, model: 'textembedding-gecko@003', dimensions: 768)
      sql = extract_option_from_sql(@builder, :embedding)

      assert_equal "ai.embedding_litellm('vertex_ai/textembedding-gecko@003', 768)", sql
    end

    should 'handle cohere input_type parameter' do
      @builder.embedding(:cohere, model: 'embed-english-v3.0', dimensions: 1024, input_type: 'search_document')
      sql = extract_option_from_sql(@builder, :embedding)

      assert_equal "ai.embedding_litellm('cohere/embed-english-v3.0', 1024, input_type => 'search_document')", sql
    end

    should 'not modify model name if it already has provider prefix' do
      @builder.embedding(:cohere, model: 'cohere/embed-english-v3.0', dimensions: 1024)
      sql = extract_option_from_sql(@builder, :embedding)

      assert_equal "ai.embedding_litellm('cohere/embed-english-v3.0', 1024)", sql
    end

    should 'raise error for unsupported provider' do
      error = assert_raises ArgumentError do
        @builder.embedding(:unsupported, model: 'test', dimensions: 512)
      end
      assert_includes error.message, 'Unsupported provider: unsupported'
      assert_includes error.message, 'Supported providers:'
    end
  end

  context '#chunking' do
    should 'configure character chunking' do
      @builder.chunking(:character, size: 512, overlap: 50)
      sql = extract_option_from_sql(@builder, :chunking)

      assert_equal 'ai.chunking_character_text_splitter(512, 50)', sql
    end

    should 'configure recursive chunking' do
      @builder.chunking(:recursive, size: 1024, overlap: 100)
      sql = extract_option_from_sql(@builder, :chunking)

      assert_equal 'ai.chunking_recursive_character_text_splitter(1024, 100)', sql
    end

    should 'raise error for unsupported chunking type' do
      error = assert_raises ArgumentError do
        @builder.chunking(:unsupported, size: 512, overlap: 50)
      end
      assert_equal 'Unsupported chunking type: unsupported', error.message
    end
  end

  context '#formatting' do
    should 'set formatting template' do
      template = 'Title: $title Body: $chunk'
      @builder.formatting(template)
      sql = extract_option_from_sql(@builder, :formatting)

      assert_equal "ai.formatting_python_template('#{template}')", sql
    end
  end

  context '#to_sql' do
    should 'raise error when loading column is missing' do
      error = assert_raises PgaiRails::VectorizerError do
        @builder.to_sql
      end
      assert_equal 'Loading column is required', error.message
    end

    should 'raise error when embedding configuration is missing' do
      @builder.loading_column('content')
      error = assert_raises PgaiRails::VectorizerError do
        @builder.to_sql
      end
      assert_equal 'Embedding configuration is required', error.message
    end

    should 'generate complete SQL with all options' do
      @builder.loading_column('content')
      @builder.embedding(:ollama, model: 'test-model', dimensions: 768)
      @builder.chunking(:character, size: 512, overlap: 50)
      @builder.formatting('Title: $title Body: $chunk')

      sql = @builder.to_sql

      assert_includes sql, 'SELECT ai.create_vectorizer('
      assert_includes sql, "'posts'::regclass"
      assert_includes sql, "name => 'test_vectorizer'"
      assert_includes sql, "loading => ai.loading_column('content')"
      assert_includes sql, "embedding => ai.embedding_ollama('test-model', 768"
      assert_includes sql, 'chunking => ai.chunking_character_text_splitter(512, 50)'
      assert_includes sql, "formatting => ai.formatting_python_template('Title: $title Body: $chunk')"
    end

    should 'generate SQL with minimal required options' do
      @builder.loading_column('content')
      @builder.embedding(:ollama, model: 'test-model', dimensions: 768)

      sql = @builder.to_sql

      assert_includes sql, 'SELECT ai.create_vectorizer('
      assert_includes sql, "'posts'::regclass"
      assert_includes sql, "name => 'test_vectorizer'"
      assert_includes sql, "loading => ai.loading_column('content')"
      assert_includes sql, "embedding => ai.embedding_ollama('test-model', 768"
      assert_not_includes sql, 'chunking =>'
      assert_not_includes sql, 'formatting =>'
    end
  end

  private

  def extract_option_from_sql(builder, option)
    # Access the private @options instance variable to test individual configurations
    builder.instance_variable_get(:@options)[option]
  end
end
