# frozen_string_literal: true

require 'rails/railtie'
require_relative 'migration_helpers'

module PgaiRails
  class Railtie < Rails::Railtie
    config.pgai_rails = ActiveSupport::OrderedOptions.new

    # Load dotenv early in the boot process
    initializer 'pgai_rails.dotenv', before: :load_environment_config do
      require 'dotenv'

      # Only attempt to load .env files if we're in a Rails app with a root
      if defined?(Rails.root) && Rails.root && Rails.root.join('.env').exist?
        Dotenv.load(
          Rails.root.join('.env.local'),
          Rails.root.join(".env.#{Rails.env}"),
          Rails.root.join('.env'),
        )
      end
    rescue LoadError
      # dotenv is optional - don't fail if not available
    end

    initializer 'pgai_rails.configuration' do |app|
      PgaiRails.configure do |config|
        app.config.pgai_rails.each do |k, v|
          config.public_send(:"#{k}=", v)
        end
      end
    end

    initializer 'pgai_rails.migration_helpers' do
      ActiveRecord::Migration.include PgaiRails::MigrationHelpers
    end

    rake_tasks do
      load 'tasks/pgai_rails.rake'
    end

    generators do
      require_relative '../generators/pgai_rails/migration_generator'
      require_relative '../generators/pgai_rails/model_generator'
    end
  end
end
