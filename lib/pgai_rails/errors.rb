# frozen_string_literal: true

module PgaiRails
  class Error < StandardError; end

  class ConfigurationError < Error; end

  class ExtensionNotAvailableError < Error; end

  class EmbeddingError < Error; end

  class VectorizerError < Error; end

  class SearchError < Error; end
end
