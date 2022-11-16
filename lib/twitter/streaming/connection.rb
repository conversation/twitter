require 'http/parser'
require 'openssl'
require 'resolv'

module Twitter
  module Streaming
    class Connection
      def initialize(opts = {})
        @tcp_socket_class = opts.fetch(:tcp_socket_class) { TCPSocket }
        @ssl_socket_class = opts.fetch(:ssl_socket_class) { OpenSSL::SSL::SSLSocket }
      end
      attr_reader :tcp_socket_class, :ssl_socket_class

      def stream(request, response)
        client_context = OpenSSL::SSL::SSLContext.new
        client         = @tcp_socket_class.new(Resolv.getaddress(request.socket_host), request.socket_port)
        ssl_client     = @ssl_socket_class.new(client, client_context)

        ssl_client.connect
        request.stream(ssl_client)
        while body = ssl_client.readpartial(1024) # rubocop:disable AssignmentInCondition
          response << body
        end
      end

      def connected?
        # Connection is established and broken within #stream, so we consider it closed anywhere else.
        # For comparison, see NonblockingConnection.
        false
      end

      def close
        # No-op, as we only have a connection within #stream
      end
    end
  end
end
