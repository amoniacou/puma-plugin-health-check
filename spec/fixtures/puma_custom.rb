# frozen_string_literal: true

require 'puma_plugin_health_check'

app_path = File.expand_path('app.rb', __dir__)

health_check_port = ENV.fetch('HEALTH_CHECK_PORT', '0').to_i

bind 'tcp://127.0.0.1:0'
workers 0
app_dir __dir__

app do
  require app_path
  App
end

PumaPluginHealthCheck.configure do |c|
  c.port = health_check_port
  c.liveness_path = '/healthz/live'
  c.readiness_path = '/healthz/ready'
end

plugin :health_check
