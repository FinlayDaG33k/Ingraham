require "socket"
require "../test-response-codes"

module Ingraham
  struct SystemTester
    def get_primary_ip()
      # Create an UDP socket
      socket = UDPSocket.new

      # Connect to external IP
      # This doesn't actually send packets.
      socket.connect "8.8.8.8", 1

      # Check whether we have a local IP
      begin
        if socket.local_address.address.nil?
          return TestResponseCodes::UNKNOWN.value
        end
        return TestResponseCodes::OK.value
      rescue exception
        return TestResponseCodes::FAIL.value

      ensure 
        # Close the socket
        socket.close
      end

      begin
        # Connect to an external IP. No packets are actually sent.
        socket.connect "8.8.8.8", 1
        
        # Retrieve the local IP assigned to this socket connection
        puts socket.local_address.address
        if local_address = socket.local_address
          return local_address.address
        end
      rescue ex : Socket::Error
        # Handle situations where there is no network interface available
        nil
      ensure
        socket.close
      end
    end
  end
end