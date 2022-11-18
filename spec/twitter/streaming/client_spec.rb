require 'helper'

describe Twitter::Streaming::Client do
  before do
    @client = Twitter::Streaming::Client.new
  end

  class FakeConnection
    attr_reader :request, :response

    def initialize(body)
      @body = body
    end

    def stream(request, response)
      @request = request
      @response = response

      @body.each_line do |line|
        response.on_body(line)
      end
    end

    def connected?
      false
    end

    def close
    end
  end

  describe '#initialize' do
    it 'constructs a connection' do
      expect(Twitter::Streaming::Client.new.connection).to be_a(Twitter::Streaming::Connection)
    end

    it 'constructs a non-blocking connection' do
      expect(Twitter::Streaming::Client.new(nonblocking: true).connection).to be_a(Twitter::Streaming::NonblockingConnection)
    end
  end

  describe '#connected?' do
    it 'returns whether the connection is connected' do
      @client.connection = FakeConnection.new('')
      expect(@client.connection).to receive(:connected?).and_return(false)
      expect(@client.connected?).to be(false)
    end
  end

  describe '#close' do
    it 'closes the connection' do
      @client.connection = FakeConnection.new('')
      expect(@client.connection).to receive(:close)
      @client.close
    end
  end

  describe '#before_request' do
    it 'runs before a request' do
      @client.connection = FakeConnection.new(fixture('track_streaming.json'))
      var = false
      @client.before_request do
        var = true
      end
      expect(var).to be false
      @client.user {}
      expect(var).to be true
    end
  end

  describe '#filter' do
    it 'returns an arary of Tweets' do
      @client.connection = FakeConnection.new(fixture('track_streaming.json'))
      objects = []
      @client.filter(track: 'india') do |object|
        objects << object
      end
      expect(objects.size).to eq(2)
      expect(objects.first).to be_a Twitter::Tweet
      expect(objects.first.text).to eq "The problem with your code is that it's doing exactly what you told it to do."
    end
  end

  describe '#firehose' do
    it 'returns an arary of Tweets' do
      @client.connection = FakeConnection.new(fixture('track_streaming.json'))
      objects = []
      @client.firehose do |object|
        objects << object
      end
      expect(objects.size).to eq(2)
      expect(objects.first).to be_a Twitter::Tweet
      expect(objects.first.text).to eq "The problem with your code is that it's doing exactly what you told it to do."
    end
  end

  describe '#sample' do
    it 'returns an arary of Tweets' do
      @client.connection = FakeConnection.new(fixture('track_streaming.json'))
      objects = []
      @client.sample do |object|
        objects << object
      end
      expect(objects.size).to eq(2)
      expect(objects.first).to be_a Twitter::Tweet
      expect(objects.first.text).to eq "The problem with your code is that it's doing exactly what you told it to do."
    end
  end

  describe '#site' do
    context 'with a user ID passed' do
      it 'returns an arary of Tweets' do
        @client.connection = FakeConnection.new(fixture('track_streaming.json'))
        objects = []
        @client.site(7_505_382) do |object|
          objects << object
        end
        expect(objects.size).to eq(2)
        expect(objects.first).to be_a Twitter::Tweet
        expect(objects.first.text).to eq "The problem with your code is that it's doing exactly what you told it to do."
      end
    end
    context 'with a user object passed' do
      it 'returns an arary of Tweets' do
        @client.connection = FakeConnection.new(fixture('track_streaming.json'))
        objects = []
        user = Twitter::User.new(id: 7_505_382)
        @client.site(user) do |object|
          objects << object
        end
        expect(objects.size).to eq(2)
        expect(objects.first).to be_a Twitter::Tweet
        expect(objects.first.text).to eq "The problem with your code is that it's doing exactly what you told it to do."
      end
    end
  end

  describe '#user' do
    it 'returns an arary of Tweets' do
      @client.connection = FakeConnection.new(fixture('track_streaming_user.json'))
      objects = []
      @client.user do |object|
        objects << object
      end
      expect(objects.size).to eq(6)
      expect(objects[0]).to be_a Twitter::Streaming::FriendList
      expect(objects[0]).to eq([488_736_931, 311_444_249])
      expect(objects[1]).to be_a Twitter::Tweet
      expect(objects[1].text).to eq("The problem with your code is that it's doing exactly what you told it to do.")
      expect(objects[2]).to be_a Twitter::DirectMessage
      expect(objects[2].text).to eq('hello bot')
      expect(objects[3]).to be_a Twitter::Streaming::Event
      expect(objects[3].name).to eq(:follow)
      expect(objects[4]).to be_a Twitter::Streaming::DeletedTweet
      expect(objects[4].id).to eq(272_691_609_211_117_568)
      expect(objects[5]).to be_a Twitter::Streaming::StallWarning
      expect(objects[5].code).to eq('FALLING_BEHIND')
    end
  end

  context 'with a non-blocking connection' do
    it "maintains the request and response between polls" do
      @client.connection = FakeConnection.new(fixture('track_streaming.json'))

      @client.filter(track: 'india') {}

      # The nonblocking connection would now be connected, so stub our fake connection as such
      allow(@client.connection).to receive(:connected?).and_return(true)

      expect {
        @client.filter(track: 'india') {}
      }.not_to(change { [@client.connection.request.object_id, @client.connection.response.object_id] })
    end
  end
end
