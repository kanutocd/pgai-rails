# frozen_string_literal: true

require 'active_record'

module PgaiRails
  class ExtensionChecker
    class << self
      def pgai_available?
        @pgai_available ||= begin
          ActiveRecord::Base.connection.execute(
            "SELECT 1 FROM pg_extension WHERE extname = 'ai'",
          ).any?
        rescue StandardError => e
          if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
            Rails.logger.debug { "PGAI extension check failed: #{e.message}" }
          end
          false
        end
      end

      def pgvector_available?
        @pgvector_available ||= begin
          ActiveRecord::Base.connection.execute(
            "SELECT 1 FROM pg_extension WHERE extname = 'vector'",
          ).any?
        rescue StandardError => e
          if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
            Rails.logger.debug { "pgvector extension check failed: #{e.message}" }
          end
          false
        end
      end

      def reset_cache!
        @pgai_available = nil
        @pgvector_available = nil
      end
    end
  end
end
