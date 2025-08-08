# frozen_string_literal: true

require_relative 'vectorizer_builder'

module PgaiRails
  module MigrationHelpers
    def create_vectorizer(table_name, name: nil, &)
      name ||= "#{table_name}_vectorizer"
      builder = VectorizerBuilder.new(table_name, name)
      builder.instance_eval(&) if block_given?

      execute builder.to_sql
    end

    def drop_vectorizer(name)
      execute "SELECT ai.drop_vectorizer('#{name}');"
    end
  end
end
