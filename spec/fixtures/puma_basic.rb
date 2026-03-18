# frozen_string_literal: true

require_relative '../../lib/puma/plugin/health_check'

rackup File.expand_path('config.ru', __dir__)
bind 'tcp://127.0.0.1:0'
workers 0

PumaPluginHealthCheck.configure do |c|
  c.port = 0
end

plugin :health_check
