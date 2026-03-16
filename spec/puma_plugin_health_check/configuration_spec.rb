# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PumaPluginHealthCheck::Configuration do
  subject(:config) { described_class.new }

  describe 'defaults' do
    it 'has default port 9393' do
      expect(config.port).to eq(9393)
    end

    it 'has default bind 0.0.0.0' do
      expect(config.bind).to eq('0.0.0.0')
    end

    it 'has default readiness_path' do
      expect(config.readiness_path).to eq('/checks/_readiness')
    end

    it 'has default liveness_path' do
      expect(config.liveness_path).to eq('/checks/_liveness')
    end
  end

  describe 'custom values' do
    it 'allows setting port' do
      config.port = 8080
      expect(config.port).to eq(8080)
    end

    it 'allows setting bind' do
      config.bind = '127.0.0.1'
      expect(config.bind).to eq('127.0.0.1')
    end

    it 'allows setting readiness_path' do
      config.readiness_path = '/healthz/ready'
      expect(config.readiness_path).to eq('/healthz/ready')
    end

    it 'allows setting liveness_path' do
      config.liveness_path = '/healthz/live'
      expect(config.liveness_path).to eq('/healthz/live')
    end
  end
end
