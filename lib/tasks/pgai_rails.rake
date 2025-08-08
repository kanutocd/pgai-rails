# frozen_string_literal: true

namespace :pgai_rails do
  desc 'Generate pgai_rails initializer configuration'
  task init: :environment do
    require 'rails'
    require 'fileutils'
    require 'yaml'

    initializer_path = Rails.root.join('config/initializers/pgai_rails.rb')
    initializer_template_path = File.expand_path('../templates/initializer.rb', __dir__)

    docker_compose_path = Rails.root.join('docker-compose.yml')
    docker_compose_template_path = File.expand_path('../templates/docker-compose.yml', __dir__)

    # Handle initializer file
    if File.exist?(initializer_path)
      puts "⚠️  Initializer already exists at #{initializer_path}"
      print 'Overwrite? [y/N]: '
      response = $stdin.gets.strip.downcase
      unless ['y', 'yes'].include?(response)
        puts '❌ Aborted. No changes made.'
        exit
      end
    end

    # Ensure the directory exists
    FileUtils.mkdir_p(File.dirname(initializer_path))

    # Copy the initializer template
    initializer_content = File.read(initializer_template_path)
    File.write(initializer_path, initializer_content)

    puts "✅ Created pgai_rails initializer at #{initializer_path}"

    # Handle docker-compose.yml file
    docker_compose_template_content = File.read(docker_compose_template_path)

    if File.exist?(docker_compose_path)
      puts "⚠️  docker-compose.yml already exists at #{docker_compose_path}"
      print 'Merge with existing file? [Y/n]: '
      response = $stdin.gets.strip.downcase

      if ['n', 'no'].include?(response)
        puts '⏭️  Skipped docker-compose.yml generation'
      else
        # Merge the files
        existing_content = YAML.load_file(docker_compose_path)
        template_content = YAML.load(docker_compose_template_content)

        # Merge services
        existing_content['services'] ||= {}
        template_content['services'].each do |service_name, service_config|
          if existing_content['services'][service_name]
            puts "⚠️  Service '#{service_name}' already exists in docker-compose.yml"
            print "Overwrite service '#{service_name}'? [y/N]: "
            overwrite_response = $stdin.gets.strip.downcase
            if ['y', 'yes'].include?(overwrite_response)
              existing_content['services'][service_name] = service_config
              puts "✅ Updated service '#{service_name}'"
            else
              puts "⏭️  Skipped service '#{service_name}'"
            end
          else
            existing_content['services'][service_name] = service_config
            puts "✅ Added service '#{service_name}'"
          end
        end

        # Merge volumes
        existing_content['volumes'] ||= {}
        template_content['volumes']&.each do |volume_name, volume_config|
          unless existing_content['volumes'][volume_name]
            existing_content['volumes'][volume_name] = volume_config
            puts "✅ Added volume '#{volume_name}'"
          end
        end

        # Write merged content
        File.write(docker_compose_path, existing_content.to_yaml)
        puts "✅ Merged docker-compose.yml at #{docker_compose_path}"
      end
    else
      # Create new docker-compose.yml
      File.write(docker_compose_path, docker_compose_template_content)
      puts "✅ Created docker-compose.yml at #{docker_compose_path}"
    end

    puts
    puts '🎉 Setup complete!'
    puts
    puts 'Next steps:'
    puts '1. Review and customize the configuration in the initializer'
    puts '2. Start the development environment with:'
    puts '   docker compose up -d'
    puts '3. Set up your API keys as environment variables or in .env file'
    puts '4. Create your first vectorizer migration with:'
    puts '   rails generate migration CreatePostVectorizer'
    puts
  end

  desc 'Check pgai extension status and configuration'
  task status: :environment do
    unless defined?(Rails)
      puts '❌ This task requires a Rails environment'
      puts '   Run with: rails pgai_rails:status'
      exit 1
    end
    require 'pgai_rails'

    puts '🔍 PgaiRails Status Check'
    puts '=' * 50

    # Check extensions
    puts '📦 Extensions:'
    if PgaiRails::ExtensionChecker.pgai_available?
      puts '  ✅ pgai extension: Available'
    else
      puts '  ❌ pgai extension: Not available'
      puts '     Install with: CREATE EXTENSION ai CASCADE;'
    end

    if PgaiRails::ExtensionChecker.pgvector_available?
      puts '  ✅ pgvector extension: Available'
    else
      puts '  ❌ pgvector extension: Not available'
      puts '     Install with: CREATE EXTENSION vector CASCADE;'
    end

    puts

    # Check configuration
    config = PgaiRails.configuration
    puts '⚙️  Configuration:'
    puts "  Default provider: #{config.default_provider}"
    puts "  Default model: #{config.default_model}"
    puts "  Default dimensions: #{config.default_dimensions}"
    puts "  Ollama base URL: #{config.ollama_base_url}"
    puts "  Auto vectorize: #{config.auto_vectorize}"
    puts "  Fallback on error: #{config.fallback_on_error}"

    unless config.provider_configs.empty?
      puts
      puts '  Provider configurations:'
      config.provider_configs.each do |provider, settings|
        puts "    #{provider}: #{settings.keys.join(', ')}"
      end
    end

    puts

    # Check vectorizers if pgai is available
    if PgaiRails::ExtensionChecker.pgai_available?
      begin
        vectorizers = ActiveRecord::Base.connection.execute(
          'SELECT name, config FROM ai.vectorizer ORDER BY name',
        )

        if vectorizers.any?
          puts '🤖 Active Vectorizers:'
          vectorizers.each do |vectorizer|
            puts "  • #{vectorizer['name']}"
          end
        else
          puts '📝 No vectorizers found'
          puts '   Create one with a migration using create_vectorizer'
        end
      rescue StandardError => e
        puts "❌ Error checking vectorizers: #{e.message}"
      end
    end

    puts
  end

  desc 'List all available embedding providers'
  task providers: :environment do
    require 'pgai_rails'

    puts '🤖 Supported Embedding Provider'
    puts '=' * 50
    puts

    puts '📡 Direct Provider (Native pgai integration):'
    PgaiRails::Provider.direct_providers.each do |provider|
      config = PgaiRails::Provider.config_for(provider)
      models = config[:common_models].keys.first(3).join(', ')
      models += ', ...' if config[:common_models].size > 3
      puts "  • #{provider.to_s.ljust(12)} - #{config[:description]}"
      puts "    #{' ' * 14} Models: #{models}" unless models.empty?
    end
    puts

    puts '🔗 LiteLLM Provider (Via LiteLLM integration):'
    litellm_providers = PgaiRails::Provider.litellm_providers.reject { |p| p == :litellm }
    litellm_providers.each do |provider|
      config = PgaiRails::Provider.config_for(provider)
      models = config[:common_models].keys.first(2).join(', ')
      models += ', ...' if config[:common_models].size > 2
      api_key_info = config[:api_key_required] ? ' (API key required)' : ''
      puts "  • #{provider.to_s.ljust(12)} - #{config[:description]}#{api_key_info}"
      puts "    #{' ' * 14} Models: #{models}" unless models.empty?
    end
    puts

    # Show direct LiteLLM usage
    config = PgaiRails::Provider.config_for(:litellm)
    puts '🔧 Direct LiteLLM Usage:'
    puts "  • litellm     - #{config[:description]}"
    puts "    #{' ' * 14} Use full model strings like 'cohere/embed-english-v3.0'"
    puts

    puts '💡 Example usage in migrations:'
    puts <<~EXAMPLE
      create_vectorizer 'posts' do
        loading_column 'content'
        embedding :ollama, model: 'nomic-embed-text', dimensions: 768
        chunking :character, size: 512, overlap: 50
      end
    EXAMPLE
    puts
  end

  desc 'Reset pgai extension caches'
  task reset_cache: :environment do
    unless defined?(Rails)
      puts '❌ This task requires a Rails environment'
      puts '   Run with: rails pgai_rails:reset_cache'
      exit 1
    end
    PgaiRails::ExtensionChecker.reset_cache!
    puts '✅ Extension caches reset'
  end
end
