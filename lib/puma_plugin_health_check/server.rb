# frozen_string_literal: true

require 'socket'

module PumaPluginHealthCheck
  class Server
    def initialize(launcher:, configuration:)
      @launcher = launcher
      @configuration = configuration
      @server = nil
      @thread = nil
    end

    def start
      @server = TCPServer.new(@configuration.bind, @configuration.port)

      expected_workers = @launcher.options[:workers] || 0

      @thread = Thread.new do
        loop do
          client = @server.accept
          handle_request(client, expected_workers)
        rescue IOError
          break
        end
      end
    end

    def stop
      @server&.close
      @thread&.join(5)
      @thread&.kill
      @server = nil
      @thread = nil
    end

    def running?
      !@thread.nil? && @thread.alive?
    end

    def port
      @server&.addr&.[](1)
    end

    private

    def handle_request(client, expected_workers)
      request_line = client.gets
      status = resolve_status(request_line, expected_workers)
      client.print "HTTP/1.1 #{status}\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n{}"
    rescue StandardError
      # ignore client errors
    ensure
      client.close
    end

    def resolve_status(request_line, expected_workers)
      if request_line&.include?(@configuration.liveness_path)
        200
      elsif request_line&.include?(@configuration.readiness_path)
        readiness_status(expected_workers)
      else
        404
      end
    end

    def readiness_status(expected_workers)
      return 200 if expected_workers.zero?

      booted_workers = @launcher.stats[:booted_workers] || 0
      booted_workers == expected_workers ? 200 : 503
    end
  end
end
