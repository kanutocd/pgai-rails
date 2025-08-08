# frozen_string_literal: true

require 'test_helper'

class MigrationHelpersTest < Minitest::Test
  # Create a test class that includes the migration helpers
  class TestMigration
    include PgaiRails::MigrationHelpers

    attr_reader :executed_sql

    def execute(sql)
      @executed_sql = sql
    end
  end

  def setup
    @migration = TestMigration.new
  end

  context '#create_vectorizer' do
    should 'create vectorizer with default name' do
      @migration.create_vectorizer('posts') do
        loading_column 'content'
        embedding :ollama, model: 'test-model', dimensions: 768
      end

      assert_includes @migration.executed_sql, "name => 'posts_vectorizer'"
      assert_includes @migration.executed_sql, "'posts'::regclass"
      assert_includes @migration.executed_sql, "loading => ai.loading_column('content')"
      assert_includes @migration.executed_sql, "embedding => ai.embedding_ollama('test-model', 768"
    end

    should 'create vectorizer with custom name' do
      @migration.create_vectorizer('posts', name: 'custom_vectorizer') do
        loading_column 'body'
        embedding :ollama, model: 'test-model', dimensions: 768
      end

      assert_includes @migration.executed_sql, "name => 'custom_vectorizer'"
      assert_includes @migration.executed_sql, "loading => ai.loading_column('body')"
    end

    should 'create vectorizer with all options' do
      @migration.create_vectorizer('articles') do
        loading_column 'content'
        embedding :ollama, model: 'nomic-embed-text', dimensions: 768
        chunking :character, size: 512, overlap: 50
        formatting 'Title: $title Body: $chunk'
      end

      sql = @migration.executed_sql

      assert_includes sql, "'articles'::regclass"
      assert_includes sql, "name => 'articles_vectorizer'"
      assert_includes sql, "loading => ai.loading_column('content')"
      assert_includes sql, "embedding => ai.embedding_ollama('nomic-embed-text', 768"
      assert_includes sql, 'chunking => ai.chunking_character_text_splitter(512, 50)'
      assert_includes sql, "formatting => ai.formatting_python_template('Title: $title Body: $chunk')"
    end

    should 'raise error without proper configuration' do
      error = assert_raises PgaiRails::VectorizerError do
        @migration.create_vectorizer('posts')
      end

      assert_equal 'Loading column is required', error.message
    end
  end

  context '#drop_vectorizer' do
    should 'generate correct SQL for dropping vectorizer' do
      @migration.drop_vectorizer('test_vectorizer')

      assert_equal "SELECT ai.drop_vectorizer('test_vectorizer');", @migration.executed_sql
    end
  end
end
