require "socket"
require "../test-response-codes"

module Ingraham
  record DnsResponse,
    bytes : Int32,
    buffer : Bytes

  struct DnsTester
    @domain = "mikrotik.com"
    @port = 53

    def initialize(@server : String)
    end

    def test()
      # Allocate memory for packet
      packet = IO::Memory.new

      # Add our header
      packet = self.build_header(packet)

      # Add our question
      packet = self.build_question(packet)

      # Send out the packet and receive our response
      begin
        response = self.send_and_receive(packet)
      rescue
        return TestResponseCodes::FAIL.value
      end

      # Parse our response then return the status code
      return parse_response(packet, response)
    end

    def build_header(packet)
      # Add the Transaction ID
      # TODO: Randomize
      packet.write_bytes(0x1234.to_u16, IO::ByteFormat::BigEndian)

      # Add the flags (Standard Query, Recursion Desired)
      packet.write_bytes(0x0100.to_u16, IO::ByteFormat::BigEndian)

      # Add amount of Questions (1)
      packet.write_bytes(0x0001.to_u16, IO::ByteFormat::BigEndian)

      # Add "Answer RRs", "Authority RRs" and "Additional RRs
      # Idk what these do (they were part of the reference code)
      packet.write_bytes(0x0000.to_u16, IO::ByteFormat::BigEndian)
      packet.write_bytes(0x0000.to_u16, IO::ByteFormat::BigEndian)
      packet.write_bytes(0x0000.to_u16, IO::ByteFormat::BigEndian)

      # Return our packet
      return packet
    end

    def build_question(packet)
      # Encode our domain to bytes
      # - Split domain at each "."
      # - Convert each part to a UInt8
      # - Convert each part to a Slice
      @domain.split('.').each do |part|
        packet.write_byte(part.bytesize.to_u8)
        packet.write(part.to_slice)
      end

      # Add Null terminator
      packet.write_byte(0x00.to_u8)

      # Add record type (A record)
      # TODO: Add IPv6 support
      packet.write_bytes(0x0001.to_u16, IO::ByteFormat::BigEndian)

      # Add Class (IN)
      packet.write_bytes(0x0001.to_u16, IO::ByteFormat::BigEndian)

      # Return our packet
      return packet
    end

    def parse_response(request_packet, response)
      # Get size of original question
      question_len = request_packet.bytesize

      # Read response into new bit of memory
      # Then skip the original question
      buffer = Bytes.new(512)
      response_reader = IO::Memory.new(response.buffer[0, response.bytes])
      response_reader.skip(question_len) 

      # Parse the response
      begin
        # Read Name Pointer (usually 0xc000 because of compression) using the correct Type tokens
        name_pointer = response_reader.read_bytes(UInt16, IO::ByteFormat::BigEndian)
        
        type = response_reader.read_bytes(UInt16, IO::ByteFormat::BigEndian)
        cls = response_reader.read_bytes(UInt16, IO::ByteFormat::BigEndian)
        ttl = response_reader.read_bytes(UInt32, IO::ByteFormat::BigEndian)
        rdlength = response_reader.read_bytes(UInt16, IO::ByteFormat::BigEndian)

        if type == 1 && rdlength == 4 # Type 1 is Type A (IPv4)
          ip_bytes = Bytes.new(4)
          response_reader.read(ip_bytes)
          
          # Correctly read each individual index of the byte array
          ip_address = "#{ip_bytes[0]}.#{ip_bytes[1]}.#{ip_bytes[2]}.#{ip_bytes[3]}"
          #puts "Successfully Resolved IP: #{ip_address}"
          return TestResponseCodes::OK.value
        else
          puts "Received resource type: #{type} (Expected Type 1 / A Record)"
          return TestResponseCodes::UNKNOWN.value
        end
      rescue ex
        puts "Failed to parse response: #{ex.message}"
        return TestResponseCodes::UNKNOWN.value
      end
    end

    def send_and_receive(packet)
      # Open new UDP Socket
      # TODO: Add TCP support
      socket = UDPSocket.new
      socket.connect(@server, @port)

      # Add timeouts
      socket.read_timeout = 5.seconds
      socket.write_timeout = 5.seconds

      # Write out packet to socket
      socket.write(packet.to_slice)

      # Receive the raw response buffer
      buffer = Bytes.new(512)
      bytes_received, client_addr = socket.receive(buffer)

      # Close the socket to save resources
      socket.close

      # Return our received bytes
      return DnsResponse.new bytes_received, buffer
    end    
  end
end