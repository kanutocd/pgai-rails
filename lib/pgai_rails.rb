# frozen_string_literal: true

require_relative 'pgai_rails/version'
require_relative 'pgai_rails/configuration'
require_relative 'pgai_rails/errors'
require_relative 'pgai_rails/provider'
require_relative 'pgai_rails/extension_checker'
require_relative 'pgai_rails/vectorizer_builder'
require_relative 'pgai_rails/migration_helpers'

module PgaiRails
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end

require_relative 'pgai_rails/railtie' if defined?(Rails::Railtie)
