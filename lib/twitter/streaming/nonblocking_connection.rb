require 'http/parser'
require 'openssl'
require 'resolv'

module Twitter
  module Streaming
    class NonblockingConnection
      def initialize(opts = {})
        @stream_connected = false
        @tcp_socket_class = opts.fetch(:tcp_socket_class) { TCPSocket }
        @ssl_socket_class = opts.fetch(:ssl_socket_class) { OpenSSL::SSL::SSLSocket }
        @timeout = opts.fetch(:timeout, 60)
      end
      attr_reader :tcp_socket_class, :ssl_socket_class

      def stream(request, response)
        start_stream(request) unless @stream_connected
        start_time = Time.now

        begin
          while body = @ssl_client.read_nonblock(1024) # rubocop:disable AssignmentInCondition
            response << body
          end
        rescue IO::WaitReadable
          # Wait for the socket to become readable (up to 1 second)
          IO.select([@ssl_client], [], [], 1)

          retry unless @timeout && Time.now > start_time + @timeout
        end
      end

      def connected?
        @stream_connected
      end

      def close
        @ssl_client.sysclose
        @stream_connected = false
      end

    private

      def start_stream(request)
        client_context = OpenSSL::SSL::SSLContext.new
        client         = @tcp_socket_class.new(Resolv.getaddress(request.socket_host), request.socket_port)
        @ssl_client     = @ssl_socket_class.new(client, client_context)
        @ssl_client.sync_close = true

        @ssl_client.connect
        request.stream(@ssl_client)

        @stream_connected = true
      end
    end
  end
end
