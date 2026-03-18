# frozen_string_literal: true

require 'puma'
require 'puma/plugin'
require_relative '../../puma_plugin_health_check/configuration'
require_relative '../../puma_plugin_health_check/server'

module PumaPluginHealthCheck
  @configuration = Configuration.new

  def self.configuration
    @configuration
  end

  def self.configure
    yield @configuration
  end

  def self.reset_configuration!
    @configuration = Configuration.new
  end
end

Puma::Plugin.create do
  def start(launcher)
    launcher.log_writer.log '* Starting health check server'

    server = PumaPluginHealthCheck::Server.new(
      launcher: launcher,
      configuration: PumaPluginHealthCheck.configuration
    )
    server.start

    config = PumaPluginHealthCheck.configuration
    launcher.log_writer.log "* Health check server listening on #{config.bind}:#{server.port}"

    launcher.events.register(:state) do |state|
      if %i[halt restart stop].include?(state)
        launcher.log_writer.log '* Stopping health check server'
        server.stop
        PumaPluginHealthCheck.reset_configuration!
      end
    end
  end
end
