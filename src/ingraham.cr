require "colorize"
require "./test-response-codes"
require "./testers/dns"
require "./testers/http"
require "./testers/https"
require "./testers/system"
require "./testers/ping"
require "./testers/mikrotik"
require "./testers/ntp"
require "./config"

module Ingraham
  # Get version from shard.yml
  VERSION = {{ read_file("#{__DIR__}/../shard.yml").split("\n").find { |l| l.starts_with?("version:") }.split(":")[1].strip }}

  # Status parser
  def self.status_parser(status_code)
    case status_code
    when TestResponseCodes::OK.value
      puts " OK!".colorize(:green)
    when TestResponseCodes::FAIL.value
      puts " FAIL!".colorize(:red)
    when TestResponseCodes::UNKNOWN.value
      puts " UNKNOWN!".colorize(:yellow)
    end
  end

  # Load config
  config = load_config()

  # Every good CLI tool has some form of banner, right?
  puts "=== Ingraham ==="
  puts "Version: #{VERSION}"
  puts "Made with <3 by FinlayDaG33k"
  
  # Start system tests
  puts "=== System Test ==="
  system_tester = SystemTester.new

  # Make sure we have a route
  print "Testing for IP..."
  status = system_tester.get_primary_ip()
  status_parser(status)
  
  # Test Ping
  puts "=== Ping Test ==="
  config.icmp.servers.each do |server|
    print "Testing Ping server \"#{server}\"..."
    ping_tester = PingTester.new server
    status = ping_tester.test()
    status_parser(status)
  end

  # Test DNS
  puts "=== DNS Test ==="
  config.dns.servers.each do |server|
    print "Testing DNS server \"#{server}\"..."
    dns_tester = DnsTester.new server
    status = dns_tester.test()
    status_parser(status)
  end

  # Test NTP
  puts "=== NTP Test ==="
  config.ntp.servers.each do |server|
    print "Testing NTP server \"#{server}\"..."
    ntp_tester = NtpTester.new server,config.ntp.max_deviation
    status = ntp_tester.test()
    status_parser(status)
  end

  # Test HTTP
  puts "=== HTTP Test ==="
  config.http.servers.each do |server|
    print "Testing HTTP server \"#{server}\"..."
    http_tester = HttpTester.new server
    status = http_tester.test()
    status_parser(status)
  end

  # Test HTTPS
  puts "=== HTTPS Test ==="
  config.http.servers.each do |server|
    print "Testing HTTPS server \"#{server}\"..."
    https_tester = HttpsTester.new server
    status = https_tester.test()
    status_parser(status)
  end

  # Test Mikrotik
  # TODO: Clean this up
  puts "=== Router Test ==="

  # Ask whether to proceed
  puts "Do you want to test your router too?"
  print "y/N > "
  confirmation = gets
  if confirmation != "y" && confirmation != "Y"
    puts "Goodbye!"
    exit
  end

  # Tell the user what happens to their credentials
  puts "You will be prompted for your router credentials."
  puts "These will only be kept in-memory while the tool runs, not written to disk."
  puts "They will definitely NEVER be sent to a server by this tool."

  # Ask for credentials
  mikrotik_host = nil
  mikrotik_username = nil
  mikrotik_password = nil
  mikrotik_interface = "ether1"
  while true
    # Ask for hostname
    while mikrotik_host.nil?
      print "IP for router: "
      mikrotik_host = gets
    end

    # Ask for username
    
    while mikrotik_username.nil?
      print "Username for router: "
      mikrotik_username = STDIN.noecho do
        STDIN.gets.try &.chomp
      end
    end
    
    # Ask for password
    while mikrotik_password.nil?
      print "Password for router: "
      mikrotik_password = STDIN.noecho do
        STDIN.gets.try &.chomp
      end
    end
  
    # Ask for WAN interface
    print "Test interface name [#{mikrotik_interface}]: "
    mikrotik_interface_temp = gets
    if !(mikrotik_interface_temp.nil? || mikrotik_interface_temp == "")
      mikrotik_interface = mikrotik_interface_temp
    end

    # Initialize tester
    mikrotik_tester = MikrotikTester.new mikrotik_host, mikrotik_username, mikrotik_password

    # Check whether we have valid credentials
    print "Testing credentials..."
    status = mikrotik_tester.test_credentials()
    status_parser(status)

    # Break if we have valid credentials
    if status == TestResponseCodes::OK.value
      break
    end

    # Reset credentials
    mikrotik_host = nil
    mikrotik_username = nil
    mikrotik_password = nil
  end

  # Make compiler happy
  if mikrotik_tester.nil?
    puts "Congratulations, you've found a bug"
    exit
  end

  # Test interface status
  print "Testing WAN interface status..."
  status = mikrotik_tester.interface_status(mikrotik_interface)
  status_parser(status)

  # Test whether interface has address
  print "Testing WAN interface address..."
  status = mikrotik_tester.interface_address(mikrotik_interface)
  status_parser(status)

  # Test whether default route exists
  print "Testing Router default route..."
  status = mikrotik_tester.default_route()
  status_parser(status)

  # Test whether interface can ping
  config.icmp.servers.each do |server|
    print "Testing Ping server \"#{server}\"..."
    status = mikrotik_tester.ping(server)
    status_parser(status)
  end
end

