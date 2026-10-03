require "socket"

module Ingraham
  record NtpResponse,
      bytes : Int32,
      buffer : Bytes

  # Delta between UNIX and NTP Epoch
  UNIX_NTP_EPOCH_DELTA = 2_208_988_800_u64
  

  # NTP Tester
  # Build on NTPv3 (not NTPv4) because that's what I am familiar with.
  struct NtpTester
    @port = 123

    def initialize(@server : String, @max_deviation : Int32)
    end

    def test()
      # Create buffer filled with 0's
      packet = Bytes.new(48)

      # Set first byte
      # Then convert binary to decimal
      # - Leap Indicator (0 - No warning)
      # - NTP Version (3 - version 3)
      # - Mode (3 - Client)
      packet[0] = 27_u8

      # Send out the packet and receive our response
      begin
        response = self.send_and_receive(packet)
      rescue
        return TestResponseCodes::UNKNOWN.value
      end

      # Extract server timestamp
      server_timestamp = IO::ByteFormat::BigEndian.decode(UInt32, response.buffer[40..44])

      # Convert NTP time to UNIX time
      unix_timestamp = server_timestamp - UNIX_NTP_EPOCH_DELTA

      # Get local time
      local_timestamp = Time.local.to_unix

      # Calculate deviation (ignore the direction)
      deviation = (local_timestamp - unix_timestamp).abs

      # Check if we are within tolerance
      return deviation < @max_deviation ? TestResponseCodes::OK.value : TestResponseCodes::FAIL.value
    end

    def send_and_receive(packet)
      # Open new UDP Socket
      socket = UDPSocket.new
      socket.connect(@server, @port)

      # Add timeouts
      socket.read_timeout = 5.seconds
      socket.write_timeout = 5.seconds

      # Write out packet to socket
      socket.write(packet.to_slice)

      # Receive the raw response buffer
      buffer = Bytes.new(48)
      bytes_received, client_addr = socket.receive(buffer)

      # Close the socket to save resources
      socket.close

      # Return our received bytes
      return NtpResponse.new bytes_received, buffer
    end
  end
end