# frozen_string_literal: true

require_relative '../../lib/puma/plugin/health_check'

rackup File.expand_path('config.ru', __dir__)
bind 'tcp://127.0.0.1:0'
workers 0

health_check_port = ENV.fetch('HEALTH_CHECK_PORT', '0').to_i

PumaPluginHealthCheck.configure do |c|
  c.port = health_check_port
  c.liveness_path = '/healthz/live'
  c.readiness_path = '/healthz/ready'
end

plugin :health_check
