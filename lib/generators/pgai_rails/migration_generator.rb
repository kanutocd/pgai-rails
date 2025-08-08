# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'

module PgaiRails
  module Generators
    class MigrationGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      desc 'Generate a migration with vectorizer setup for AI-powered semantic search'

      class_option :provider, type: :string, default: 'ollama',
                              desc: 'Embedding provider (ollama, openai, cohere, etc.)'
      class_option :model, type: :string, default: 'nomic-embed-text',
                           desc: 'Embedding model name'
      class_option :dimensions, type: :numeric, default: nil,
                                desc: 'Vector dimensions (auto-detected if not specified)'
      class_option :content_column, type: :string, default: 'content',
                                    desc: 'Column to vectorize for semantic search'
      class_option :chunk_size, type: :numeric, default: 512,
                                desc: 'Text chunk size for processing'
      class_option :chunk_overlap, type: :numeric, default: 50,
                                   desc: 'Overlap between text chunks'
      class_option :chunking_method, type: :string, default: 'character',
                                     desc: 'Chunking method (character or recursive)'

      def create_migration
        validate_options!
        migration_template 'vectorizer_migration.rb.erb', "db/migrate/create_#{file_name}_vectorizer.rb"
      end

      private

      def self.next_migration_number(_path)
        Time.now.utc.strftime('%Y%m%d%H%M%S')
      end

      def validate_options!
        provider_sym = options['provider'].to_sym
        unless PgaiRails::Provider.supported?(provider_sym)
          raise Thor::Error, "Unsupported provider: #{options['provider']}. " \
                             "Supported providers: #{PgaiRails::Provider.all.join(', ')}"
        end

        unless ['character', 'recursive'].include?(options['chunking_method'])
          raise Thor::Error, "Invalid chunking method: #{options['chunking_method']}. " \
                             'Supported methods: character, recursive'
        end

        true
      end



      def table_name
        class_name.tableize
      end

      def vectorizer_name
        "#{table_name}_vectorizer"
      end

      def provider_symbol
        ":#{options['provider']}"
      end

      def model_name
        options['model']
      end

      def dimensions
        return options['dimensions'] if options['dimensions']

        provider_sym = options['provider'].to_sym
        PgaiRails::Provider.dimensions_for_model(provider_sym, options['model'])
      end

      def content_column
        options['content_column']
      end

      def chunk_size
        options['chunk_size']
      end

      def chunk_overlap
        options['chunk_overlap']
      end

      def chunking_method
        ":#{options['chunking_method']}"
      end

      def migration_class_name
        "Create#{class_name}Vectorizer"
      end
    end
  end
end
