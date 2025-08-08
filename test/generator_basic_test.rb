# frozen_string_literal: true

require 'test_helper'

class GeneratorBasicTest < Minitest::Test
  def setup
    # Basic test to verify generators can be loaded
    require_relative '../lib/generators/pgai_rails/migration_generator'
    require_relative '../lib/generators/pgai_rails/model_generator'
  end

  def test_migration_generator_class_exists
    assert defined?(PgaiRails::Generators::MigrationGenerator)
    assert_operator PgaiRails::Generators::MigrationGenerator, :<, Rails::Generators::NamedBase
  end

  def test_model_generator_class_exists
    assert defined?(PgaiRails::Generators::ModelGenerator)
    assert_operator PgaiRails::Generators::ModelGenerator, :<, Rails::Generators::NamedBase
  end

  def test_migration_generator_has_required_methods
    generator = PgaiRails::Generators::MigrationGenerator

    assert_respond_to generator, :source_root
    assert_includes generator.instance_methods, :create_migration
  end

  def test_model_generator_has_required_methods
    generator = PgaiRails::Generators::ModelGenerator

    assert_respond_to generator, :source_root
    assert_includes generator.instance_methods, :create_model_file
    assert_includes generator.instance_methods, :create_migration_file
    assert_includes generator.instance_methods, :create_vectorizer_migration_file
  end

  def test_migration_template_exists
    template_path = File.expand_path('../lib/generators/pgai_rails/templates/vectorizer_migration.rb.erb', __dir__)

    assert_path_exists template_path, 'Migration template should exist'

    content = File.read(template_path)

    assert_includes content, 'create_vectorizer'
    assert_includes content, 'drop_vectorizer'
    assert_includes content, 'loading_column'
    assert_includes content, 'embedding'
    assert_includes content, 'chunking'
  end

  def test_model_template_exists
    template_path = File.expand_path('../lib/generators/pgai_rails/templates/model.rb.erb', __dir__)

    assert_path_exists template_path, 'Model template should exist'

    content = File.read(template_path)

    assert_includes content, 'class <%= class_name %> < ApplicationRecord'
    assert_includes content, 'semantic_search'
    assert_includes content, 'similar_records'
  end

  def test_model_migration_template_exists
    template_path = File.expand_path('../lib/generators/pgai_rails/templates/model_migration.rb.erb', __dir__)

    assert_path_exists template_path, 'Model migration template should exist'

    content = File.read(template_path)

    assert_includes content, 'create_table'
    assert_includes content, 'timestamps'
  end

  def test_migration_generator_validates_provider
    require 'pathname'
    # Mock Rails environment
    Rails.stubs(:root).returns(Pathname.new('/tmp'))

    # This should not raise an error for valid provider
    generator = PgaiRails::Generators::MigrationGenerator.new(['Post'], { 'provider' => 'ollama' })

    assert generator.send(:validate_options!)

    # This should raise an error for invalid provider
    generator = PgaiRails::Generators::MigrationGenerator.new(['Post'], { 'provider' => 'invalid' })
    assert_raises(Thor::Error) do
      generator.send(:validate_options!)
    end
  end

  def test_migration_generator_validates_chunking_method
    require 'pathname'
    Rails.stubs(:root).returns(Pathname.new('/tmp'))

    # This should not raise an error for valid chunking method
    generator = PgaiRails::Generators::MigrationGenerator.new(['Post'], { 'chunking_method' => 'character' })

    assert generator.send(:validate_options!)

    # This should raise an error for invalid chunking method
    generator = PgaiRails::Generators::MigrationGenerator.new(['Post'], { 'chunking_method' => 'invalid' })
    assert_raises(Thor::Error) do
      generator.send(:validate_options!)
    end
  end
end
