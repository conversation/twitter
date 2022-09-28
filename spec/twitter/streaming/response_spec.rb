require 'helper'

describe Twitter::Streaming::Response do
  subject { Twitter::Streaming::Response.new }

  describe '#on_headers_complete' do
    it 'should not error if status code is 200' do
      expect do
        subject << "HTTP/1.1 200 OK\r\nSome-Header: Woo\r\n\r\n"
      end.to_not raise_error
    end

    Twitter::Error::ERRORS.each do |code, klass|
      it "should raise an exception of type #{klass} for status code #{code}" do
        expect do
          subject << "HTTP/1.1 #{code} NOK\r\nSome-Header: Woo\r\n\r\n"
        end.to raise_error(klass)
      end
    end

    it 'includes rate limiting information when available' do
      reset_delay = 300
      reset_time = Time.at((Time.now.utc + reset_delay).to_i)
      expect do
        subject << "HTTP/1.1 420 NOK\r\nx-rate-limit-limit: 150\r\nx-rate-limit-remaining: 0\r\nx-rate-limit-reset: #{reset_time.to_i}\r\n\r\n"
      end.to raise_error(Twitter::Error::TooManyRequests) do |error|
        expect(error.rate_limit.limit).to eq(150)
        expect(error.rate_limit.remaining).to eq(0)
        expect(error.rate_limit.reset_at).to eq(reset_time)
        expect(error.rate_limit.reset_in).to eq(reset_delay)
      end
    end

    it 'is case-insensitive to headers' do
      reset_delay = 300
      reset_time = Time.at((Time.now.utc + reset_delay).to_i)
      expect do
        subject << "HTTP/1.1 420 NOK\r\nX-Rate-Limit-Limit: 150\r\nX-Rate-Limit-Remaining: 0\r\nX-Rate-Limit-Reset: #{reset_time.to_i}\r\n\r\n"
      end.to raise_error(Twitter::Error::TooManyRequests) do |error|
        expect(error.rate_limit.limit).to eq(150)
        expect(error.rate_limit.remaining).to eq(0)
        expect(error.rate_limit.reset_at).to eq(reset_time)
        expect(error.rate_limit.reset_in).to eq(reset_delay)
      end
    end
  end
end
