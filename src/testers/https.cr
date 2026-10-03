require "http/client"
require "../test-response-codes"

module Ingraham
  struct HttpsTester
    def initialize(@server : String)
    end

    def test()
      # Create HTTPS Client
      client = HTTP::Client.new(@server, tls: true)
      client.connect_timeout = 5.seconds

      # Send request
      begin
        response = client.head("/")
        return TestResponseCodes::OK.value
      rescue IO::TimeoutError
        return TestResponseCodes::FAIL.value
      rescue ex : OpenSSL::SSL::Error
        return TestResponseCodes::FAIL.value
      rescue ex 
        return TestResponseCodes::UNKNOWN.value
      end
    end
  end
end