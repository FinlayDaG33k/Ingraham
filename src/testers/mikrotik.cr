require "base64"
require "http/status"
require "json"

module Ingraham
  struct MikrotikTester
    def initialize(@host : String, @username : String, @password : String, @port : Int32 = 80, @ssl : Bool = false)
    end

    def test_credentials()
      # Create HTTP Client
      client = self.create_client()

      # Send request
      begin
        response = client.post("/rest/system/identity/print")

        # Check if we got a 401 response
        # Fail if we do
        if response.status == HTTP::Status::UNAUTHORIZED
          return TestResponseCodes::FAIL.value
        end

        # Check if we got a 200 response
        # Error if not
        if response.status != HTTP::Status::OK
          return TestResponseCodes::UNKNOWN.value
        end

        # All good
        return TestResponseCodes::OK.value
      rescue IO::TimeoutError
        return TestResponseCodes::UNKNOWN.value
      rescue
        return TestResponseCodes::UNKNOWN.value
      end
    end

    def interface_status(interface : String)
      # Create HTTP Client
      client = self.create_client()

      # Send request
      begin
        response = client.get("/rest/interface/#{interface}")

        # Check if we got a 200 response
        # Error if not
        if response.status != HTTP::Status::OK
          raise("Non-OK response")
        end

        # Parse JSON body
        data = JSON.parse(response.body)

        # Make sure interface is running
        if data["running"] != "true"
          return TestResponseCodes::FAIL.value
        end

        # All good
        return TestResponseCodes::OK.value
      rescue IO::TimeoutError
        return TestResponseCodes::UNKNOWN.value
      rescue
        return TestResponseCodes::UNKNOWN.value
      end
    end

    def interface_address(interface : String)
      # Create HTTP Client
      client = self.create_client()

      # Send request
      begin
        payload = {
          ".proplist" => ["interface", "address"],
          ".query" => ["interface=#{interface}"]
        }.to_json
        headers = HTTP::Headers {
          "Content-Type" => "application/json"
        }
        response = client.post("/rest/ip/address/print", headers: headers, body: payload)

        # Check if we got a 200 response
        # Error if not
        if response.status != HTTP::Status::OK
          raise("Non-OK response")
        end

        # Parse JSON body
        data = JSON.parse(response.body)

        # Make sure we have at least 1 entry
        if data.size == 0
          return TestResponseCodes::FAIL.value
        end

        # All good
        return TestResponseCodes::OK.value
      rescue IO::TimeoutError
        return TestResponseCodes::UNKNOWN.value
      rescue
        return TestResponseCodes::UNKNOWN.value
      end
    end

    def default_route()
      # Create HTTP Client
      client = self.create_client()

      # Send request
      begin
        payload = {
          ".proplist" => [".id"],
          ".query" => ["dst-address=0.0.0.0/0", "active=true", "routing-table=main"]
        }.to_json
        headers = HTTP::Headers {
          "Content-Type" => "application/json"
        }
        response = client.post("/rest/ip/route/print", headers: headers, body: payload)

        # Check if we got a 200 response
        # Error if not
        if response.status != HTTP::Status::OK
          raise("Non-OK response")
        end

        # Parse JSON body
        data = JSON.parse(response.body)

        # Make sure we have at least 1 entry
        if data.size == 0
          return TestResponseCodes::FAIL.value
        end

        # All good
        return TestResponseCodes::OK.value
      rescue IO::TimeoutError
        return TestResponseCodes::UNKNOWN.value
      rescue
        return TestResponseCodes::UNKNOWN.value
      end
    end

    def ping(host : String)
      # Create HTTP Client
      client = self.create_client()

      # Send request
      begin
        payload = {
          "address" => host,
          "count" => 4
        }.to_json
        headers = HTTP::Headers {
          "Content-Type" => "application/json"
        }
        response = client.post("/rest/ping", headers: headers, body: payload)

        # Check if we got a 200 response
        # Error if not
        if response.status != HTTP::Status::OK
          raise("Non-OK response")
        end

        # Parse JSON body
        data = JSON.parse(response.body)

        # Make sure we have at least 1 ping
        received = data[0]["received"].to_s.to_i
        if received < 1
          return TestResponseCodes::FAIL.value
        end

        # All good
        return TestResponseCodes::OK.value
      rescue IO::TimeoutError
        return TestResponseCodes::UNKNOWN.value
      rescue ex
        puts ex
        return TestResponseCodes::UNKNOWN.value
      end
    end

    private def create_client()
      # Create HTTP Client and return it
      client = HTTP::Client.new(@host, @port)
      client.connect_timeout = 5.seconds
      client.read_timeout = 5.seconds
      client.basic_auth(@username, @password)
      return client
    end
  end
end