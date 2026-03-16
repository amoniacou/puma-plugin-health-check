# frozen_string_literal: true

require 'spec_helper'
require 'socket'
require 'puma_plugin_health_check/server'
require 'puma_plugin_health_check/configuration'

RSpec.describe PumaPluginHealthCheck::Server do
  let(:config) do
    c = PumaPluginHealthCheck::Configuration.new
    c.port = 0
    c
  end

  let(:launcher) do
    instance_double('Puma::Launcher',
                    options: { workers: 2 },
                    stats: { booted_workers: 2 })
  end

  subject(:server) { described_class.new(launcher: launcher, configuration: config) }

  after { server.stop }

  def fetch(path)
    port = server.port
    socket = TCPSocket.new('127.0.0.1', port)
    socket.print "GET #{path} HTTP/1.1\r\nHost: localhost\r\n\r\n"
    response = socket.read
    socket.close
    response
  end

  describe '#start / #stop' do
    it 'starts and stops without error' do
      server.start
      expect(server).to be_running
      server.stop
      expect(server).not_to be_running
    end
  end

  describe 'liveness endpoint' do
    before { server.start }

    it 'returns 200' do
      response = fetch(config.liveness_path)
      expect(response).to include('HTTP/1.1 200')
    end
  end

  describe 'readiness endpoint' do
    before { server.start }

    context 'when all workers are booted' do
      it 'returns 200' do
        response = fetch(config.readiness_path)
        expect(response).to include('HTTP/1.1 200')
      end
    end

    context 'when not all workers are booted' do
      let(:launcher) do
        instance_double('Puma::Launcher',
                        options: { workers: 2 },
                        stats: { booted_workers: 1 })
      end

      it 'returns 503' do
        response = fetch(config.readiness_path)
        expect(response).to include('HTTP/1.1 503')
      end
    end

    context 'in single mode (no workers)' do
      let(:launcher) do
        instance_double('Puma::Launcher',
                        options: { workers: 0 },
                        stats: {})
      end

      it 'returns 200' do
        response = fetch(config.readiness_path)
        expect(response).to include('HTTP/1.1 200')
      end
    end
  end

  describe 'unknown path' do
    before { server.start }

    it 'returns 404' do
      response = fetch('/unknown')
      expect(response).to include('HTTP/1.1 404')
    end
  end
end
