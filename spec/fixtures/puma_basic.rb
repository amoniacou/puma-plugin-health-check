# frozen_string_literal: true

require 'puma_plugin_health_check'

app_path = File.expand_path('app.rb', __dir__)

bind 'tcp://127.0.0.1:0'
workers 0
app_dir __dir__

app do
  require app_path
  App
end

plugin :health_check
