# frozen_string_literal: true

module PgaiRails
  class VectorizerBuilder
    attr_reader :table_name, :name

    def initialize(table_name, name)
      @table_name = table_name
      @name = name
      @options = {}
    end

    def loading_column(column)
      @options[:loading] = "ai.loading_column('#{column}')"
    end

    def embedding(provider, model:, dimensions: nil, **opts)
      validate_provider!(provider)

      provider_config = Provider.config_for(provider)

      case provider_config[:type]
      when :direct
        build_direct_embedding(provider, model, dimensions, opts)
      when :litellm
        if provider == :litellm
          # Direct LiteLLM usage with full model string
          build_litellm_embedding(model, dimensions, opts)
        else
          # LiteLLM provider with auto-prefixing
          litellm_model = format_litellm_model(provider, model)
          build_litellm_embedding(litellm_model, dimensions, opts)
        end
      else
        raise ArgumentError, "Unsupported embedding provider: #{provider}"
      end
    end

    def chunking(type, size:, overlap:)
      case type
      when :character
        @options[:chunking] = "ai.chunking_character_text_splitter(#{size}, #{overlap})"
      when :recursive
        @options[:chunking] = "ai.chunking_recursive_character_text_splitter(#{size}, #{overlap})"
      else
        raise ArgumentError, "Unsupported chunking type: #{type}"
      end
    end

    def formatting(template)
      @options[:formatting] = "ai.formatting_python_template('#{template}')"
    end

    def to_sql
      raise VectorizerError, 'Loading column is required' unless @options[:loading]
      raise VectorizerError, 'Embedding configuration is required' unless @options[:embedding]

      options_sql = @options.map { |k, v| "#{k} => #{v}" }.join(",\n  ")

      <<~SQL.squish
        SELECT ai.create_vectorizer(
          '#{@table_name}'::regclass,
          name => '#{@name}',
          #{options_sql}
        );
      SQL
    end

    private

    def validate_provider!(provider)
      return if Provider.supported?(provider)

      raise ArgumentError,
            "Unsupported provider: #{provider}. " \
            "Supported providers: #{Provider.all.join(', ')}"
    end

    def build_direct_embedding(provider, model, dimensions, opts)
      case provider
      when :ollama
        build_ollama_embedding(model, dimensions, opts)
      when :openai
        build_openai_embedding(model, dimensions, opts)
      when :voyageai
        build_voyageai_embedding(model, dimensions, opts)
      else
        raise ArgumentError, "Unknown direct provider: #{provider}"
      end
    end

    def build_ollama_embedding(model, dimensions, opts)
      provider_config = Provider.config_for(:ollama)
      base_url = opts[:base_url] || PgaiRails.configuration.ollama_base_url
      dimensions ||= Provider.dimensions_for_model(:ollama, model) || provider_config[:default_dimensions]

      params = ["'#{model}'", dimensions.to_s]
      params << "base_url => '#{base_url}'" if base_url

      # Add optional Ollama parameters
      params << "model_parameters => '#{opts[:model_parameters]}'" if opts[:model_parameters]
      params << "keep_alive => '#{opts[:keep_alive]}'" if opts[:keep_alive]

      @options[:embedding] = "ai.embedding_ollama(#{params.join(', ')})"
    end

    def build_openai_embedding(model, dimensions, opts)
      provider_config = Provider.config_for(:openai)
      dimensions ||= Provider.dimensions_for_model(:openai, model) || provider_config[:default_dimensions]

      params = ["'#{model}'"]
      params << dimensions.to_s if dimensions
      params << "api_key_name => '#{opts[:api_key_name]}'" if opts[:api_key_name]

      @options[:embedding] = "#{provider_config[:pgai_function]}(#{params.join(', ')})"
    end

    def build_voyageai_embedding(model, dimensions, opts)
      provider_config = Provider.config_for(:voyageai)
      dimensions ||= Provider.dimensions_for_model(:voyageai, model) || provider_config[:default_dimensions]

      params = ["'#{model}'"]
      params << dimensions.to_s if dimensions
      params << "api_key_name => '#{opts[:api_key_name]}'" if opts[:api_key_name]

      @options[:embedding] = "#{provider_config[:pgai_function]}(#{params.join(', ')})"
    end

    def build_litellm_embedding(model, dimensions, opts)
      dimensions ||= PgaiRails.configuration.default_dimensions

      params = ["'#{model}'"]
      params << dimensions.to_s if dimensions
      params << "api_key_name => '#{opts[:api_key_name]}'" if opts[:api_key_name]

      # Add provider-specific parameters
      params << "input_type => '#{opts[:input_type]}'" if opts[:input_type] # Cohere-specific

      @options[:embedding] = "ai.embedding_litellm(#{params.join(', ')})"
    end

    def format_litellm_model(provider, model)
      provider_config = Provider.config_for(provider)
      return model unless provider_config

      prefix = provider_config[:litellm_prefix]
      return model unless prefix

      model.start_with?("#{prefix}/") ? model : "#{prefix}/#{model}"
    end
  end
end
