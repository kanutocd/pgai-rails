# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/model_helpers'
require 'rails/generators/migration'

module PgaiRails
  module Generators
    class ModelGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration
      include Rails::Generators::ModelHelpers

      source_root File.expand_path('templates', __dir__)

      desc 'Generate a model with vectorizer setup for AI-powered semantic search'

      argument :attributes, type: :array, default: [], banner: 'field[:type][:index] field[:type][:index]'

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
      class_option :skip_migration, type: :boolean, default: false,
                                    desc: 'Skip generating migration files'
      class_option :skip_vectorizer, type: :boolean, default: false,
                                     desc: 'Skip generating vectorizer migration'

      def create_model_file
        template 'model.rb.erb', File.join('app/models', class_path, "#{file_name}.rb")
      end

      def create_migration_file
        return if options['skip_migration']

        migration_template 'model_migration.rb.erb', "db/migrate/create_#{table_name}.rb"
      end

      def create_vectorizer_migration_file
        return if options['skip_vectorizer']

        validate_vectorizer_options!
        migration_template 'vectorizer_migration.rb.erb', "db/migrate/create_#{file_name}_vectorizer.rb"
      end

      private

      def self.next_migration_number(_path)
        @migration_number = Time.now.utc.strftime('%Y%m%d%H%M%S').to_i
        @migration_number += 1
        @migration_number.to_s
      end

      def validate_vectorizer_options!
        provider_sym = options['provider'].to_sym
        unless PgaiRails::Provider.supported?(provider_sym)
          raise Thor::Error, "Unsupported provider: #{options['provider']}. " \
                             "Supported providers: #{PgaiRails::Provider.all.join(', ')}"
        end

        return if ['character', 'recursive'].include?(options['chunking_method'])

        raise Thor::Error, "Invalid chunking method: #{options['chunking_method']}. " \
                           'Supported methods: character, recursive'
      end

      def attributes_with_index
        attributes.select { |a| !a.reference? && a.has_index? }
      end

      def reference_attributes
        attributes.select(&:reference?)
      end

      def content_column_included?
        attributes.any? { |attr| attr.name == options['content_column'] }
      end

      def vectorizer_name
        "#{table_name}_vectorizer"
      end

      def provider_symbol
        ":#{options['provider']}"
      end

      def model_name_option
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
        "Create#{class_name.pluralize}"
      end

      def vectorizer_migration_class_name
        "Create#{class_name}Vectorizer"
      end
    end
  end
end
