require "http/client"
require "../test-response-codes"

module Ingraham
  struct HttpTester
    def initialize(@server : String)
    end

    def test()
      # Create HTTP Client
      client = HTTP::Client.new(@server)
      client.connect_timeout = 5.seconds

      # Send request
      begin
        response = client.head("/")
        return TestResponseCodes::OK.value
      rescue IO::TimeoutError
        return TestResponseCodes::FAIL.value
      rescue
        return TestResponseCodes::UNKNOWN.value
      end
    end
  end
end