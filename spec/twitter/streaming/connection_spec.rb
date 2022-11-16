require 'helper'

describe Twitter::Streaming::Connection do
  describe 'initialize' do
    context 'no options provided' do
      subject(:connection) { Twitter::Streaming::Connection.new }

      it 'sets the default socket classes' do
        expect(connection.tcp_socket_class).to eq TCPSocket
        expect(connection.ssl_socket_class).to eq OpenSSL::SSL::SSLSocket
      end
    end

    context 'custom socket classes provided in opts' do
      class DummyTCPSocket; end
      class DummySSLSocket; end

      subject(:connection) do
        Twitter::Streaming::Connection.new(tcp_socket_class: DummyTCPSocket, ssl_socket_class: DummySSLSocket)
      end

      it 'sets the default socket classes' do
        expect(connection.tcp_socket_class).to eq DummyTCPSocket
        expect(connection.ssl_socket_class).to eq DummySSLSocket
      end
    end
  end

  describe 'connected?' do
    subject(:connection) { Twitter::Streaming::Connection.new }

    it 'returns false' do
      expect(connection.connected?).to be(false)
    end
  end

  describe "close" do
    subject(:connection) { Twitter::Streaming::Connection.new }

    it "performs a no-op" do
      expect(connection.close).to be_nil
    end
  end
end
