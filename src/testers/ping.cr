require "socket"
require "../test-response-codes"

module Ingraham
  struct ICMPHeader
    property type : UInt8 = 0_u8
    property code : UInt8 = 0_u8
    property checksum : UInt16 = 0_u16
    property id : UInt16 = 0_u16
    property sequence : UInt16 = 0_u16
  end

    record IcmpResponse,
      bytes : Int32,
      buffer : Bytes

   struct PingTester
    @sequence : UInt16 = 1_u16

    def initialize(@host : String)
    end

    def test()
      # Create request packet
      payload = "FinlayDaG33k\'s Internet Troubleshooter".to_slice
      packet_size = sizeof(ICMPHeader) + payload.size
      buffer = Bytes.new(packet_size)
        
      # Add Ping Type (Echo Request)
      IO::ByteFormat::BigEndian.encode(8_u8, buffer + 0)

      # Add Code 0
      IO::ByteFormat::BigEndian.encode(0_u8, buffer + 1)

      # Add a placeholder for our checksum
      IO::ByteFormat::BigEndian.encode(0_u16, buffer + 2)

      # Add an ID
      # TODO: Randomize
      IO::ByteFormat::BigEndian.encode(1234_u16, buffer + 4)

      # Add a sequence number
      IO::ByteFormat::BigEndian.encode(@sequence, buffer + 6)

      # Copy payload into packet buffer right after the header
      payload.copy_to(buffer + sizeof(ICMPHeader))

       # Calculate and inject the real checksum
      checksum = checksum(buffer)
      IO::ByteFormat::BigEndian.encode(checksum, buffer + 2)
  
      begin
        # Send our request
        response = self.send_and_receive(buffer)
        
        # Extract the ICMP header from the response. 
        # Because it's a raw socket, the first ~20 bytes will be the IPv4 header.
        ip_header_length = (response.buffer[0] & 0x0F) * 4
        icmp_response = response.buffer[ip_header_length]
        
        # ICMP Type 0 is Echo Reply
        if icmp_response == 0_u8
          return TestResponseCodes::OK.value
        else
          return TestResponseCodes::UNKNOWN.value
        end
      rescue IO::TimeoutError
        return TestResponseCodes::FAIL.value
      rescue
        return TestResponseCodes::UNKNOWN.value
      end
    end

    def send_and_receive(packet)
      # Open new ICMP socket
      socket = Socket.new(Socket::Family::INET, Socket::Type::RAW, Socket::Protocol::ICMP)
      socket.read_timeout = 2.seconds

      # Send packet over socket
      address = Socket::IPAddress.new(@host, 0)
      socket.send(packet, to: address)
        
      # Receive raw response buffer
      response_buffer = Bytes.new(1024)
      bytes_received, client_addr = socket.receive(response_buffer)

      # Close the socket to save resources
      socket.close

      # Return our received bytes
      return IcmpResponse.new bytes_received, response_buffer
    end

    def checksum(data)
      sum = 0_u32
      i = 0
      
      while i < data.size - 1
        sum += (data[i].to_u32 << 8) | data[i+1].to_u32
        i += 2
      end
      
      # Handle odd byte if present
      if i == data.size - 1
        sum += data[i].to_u32 << 8
      end
      
      # Fold 32-bit sum to 16 bits
      while (sum >> 16) > 0
        sum = (sum & 0xFFFF) + (sum >> 16)
      end
      
      ~sum.to_u16
    end
   end 

end