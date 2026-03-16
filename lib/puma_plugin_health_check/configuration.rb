# frozen_string_literal: true

module PumaPluginHealthCheck
  class Configuration
    attr_accessor :port, :bind, :readiness_path, :liveness_path

    def initialize
      @port = 9393
      @bind = '0.0.0.0'
      @readiness_path = '/checks/_readiness'
      @liveness_path = '/checks/_liveness'
    end
  end
end
