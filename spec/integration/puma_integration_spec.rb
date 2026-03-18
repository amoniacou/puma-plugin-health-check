# frozen_string_literal: true

require 'spec_helper'
require 'socket'
require 'timeout'

RSpec.describe 'Puma health check plugin integration', :integration do
  let(:fixtures_dir) { File.expand_path('../fixtures', __dir__) }
  let(:project_root) { File.expand_path('../..', __dir__) }

  def start_puma(config_file, env: {})
    config_path = File.join(fixtures_dir, config_file)
    @output_read, output_write = IO.pipe

    @pid = Process.spawn(
      env,
      'bundle', 'exec', 'puma', '-C', config_path,
      chdir: project_root,
      out: output_write,
      err: output_write
    )
    output_write.close

    @output_buffer = +''
    @output_thread = Thread.new do
      while (chunk = @output_read.read_nonblock(4096))
        @output_buffer << chunk
      end
    rescue IO::WaitReadable
      IO.select([@output_read], nil, nil, 0.1)
      retry
    rescue EOFError, IOError
      # done
    end
  end

  def wait_for_health_check_port(timeout: 10)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout

    while Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
      match = @output_buffer.match(/Health check server listening on [\d.]+:(\d+)/)
      return match[1].to_i if match

      sleep 0.1
    end

    raise "Timed out waiting for health check server. Output so far:\n#{@output_buffer}"
  end

  def http_get(port, path)
    socket = TCPSocket.new('127.0.0.1', port)
    socket.print "GET #{path} HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"
    response = socket.read
    socket.close
    response
  end

  def find_available_port
    server = TCPServer.new('127.0.0.1', 0)
    port = server.addr[1]
    server.close
    port
  end

  def stop_puma
    return unless @pid

    Process.kill('TERM', @pid)
    Timeout.timeout(10) { Process.wait(@pid) }
  rescue Errno::ESRCH, Errno::ECHILD
    # already dead
  ensure
    @output_read&.close unless @output_read&.closed?
    @output_thread&.join(2)
    @pid = nil
  end

  after { stop_puma }

  describe 'with default configuration' do
    let!(:health_port) do
      start_puma('puma_basic.rb')
      wait_for_health_check_port
    end

    it 'liveness endpoint returns 200' do
      response = http_get(health_port, '/checks/_liveness')
      expect(response).to include('HTTP/1.1 200')
    end

    it 'readiness endpoint returns 200 in single mode' do
      response = http_get(health_port, '/checks/_readiness')
      expect(response).to include('HTTP/1.1 200')
    end

    it 'unknown path returns 404' do
      response = http_get(health_port, '/unknown')
      expect(response).to include('HTTP/1.1 404')
    end
  end

  describe 'with custom configuration' do
    let(:custom_port) { find_available_port }
    let!(:health_port) do
      start_puma('puma_custom.rb', env: { 'HEALTH_CHECK_PORT' => custom_port.to_s })
      wait_for_health_check_port
    end

    it 'uses the configured port' do
      expect(health_port).to eq(custom_port)
    end

    it 'custom liveness path returns 200' do
      response = http_get(health_port, '/healthz/live')
      expect(response).to include('HTTP/1.1 200')
    end

    it 'custom readiness path returns 200' do
      response = http_get(health_port, '/healthz/ready')
      expect(response).to include('HTTP/1.1 200')
    end

    it 'default paths return 404 when custom paths configured' do
      response = http_get(health_port, '/checks/_liveness')
      expect(response).to include('HTTP/1.1 404')
    end
  end

  describe 'graceful shutdown' do
    it 'stops health check server on TERM signal' do
      start_puma('puma_basic.rb')
      health_port = wait_for_health_check_port

      response = http_get(health_port, '/checks/_liveness')
      expect(response).to include('HTTP/1.1 200')

      Process.kill('TERM', @pid)
      status = nil
      Timeout.timeout(10) { _, status = Process.wait2(@pid) }
      @pid = nil

      expect(status.exited? || status.signaled?).to be true
      expect { TCPSocket.new('127.0.0.1', health_port) }.to raise_error(Errno::ECONNREFUSED)
    end
  end
end
