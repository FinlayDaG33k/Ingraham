# Ingraham

[![Build](https://github.com/FinlayDaG33k/Ingraham/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/FinlayDaG33k/Ingraham/actions?query=branch%3Amain)

Troubleshooting tool that tests common failure points for your internet connection.  
When provided with temporary API access to a MikroTik router, also will check some common issues there!

**NOTE**: 
> Currently support IPv4 only, I do not have IPv6 networking at the moment to develop and test with.

**NOTE**:
> Currently only officially supports Windows 10 but should work with Windows 11 just fine.  
> Linux binaries are also compiled but I have no way to really test them at the moment.

## What it do?

It simply automates the things I normally check when my internet connection appears to be down:

- Whether my device has an IP (DHCP failure).
- Whether I can ping some known hosts on the WAN (overall internet check).
- Whether I can make DNS lookup (DNS server failure).
- Whether I have the right time.
- Whether I can make HTTP requests *AND* HTTPS requests (TLS failure).
  - HTTPS requests to be added in the future.
- Whether the WAN interface is up (physical connection failure/port disabled).
- Whether the WAN interface has an IP (connection to ISP).
- Whether the routing table has a default gateway (DHCP client misconfiguration).
- Whether the router can ping some known hosts on the WAN (invalid WAN configuration - eg. NAT failure).

## Usage

1. Prepare your MikroTik router by creating a user with the appropriate permissions.
   ```
   /user group
     add name=troubleshooting policy=read,api,rest-api
   /user
     add name=troubleshooter 
   ```
2. Run the troubleshooter
   ```
   # Windows (Powershell)
   ./ingraham-amd64-win.exe

   # Linux (Shell)
   chmod +x ingraham-amd64-linux
   ./ingraham-amd64-linux
   ```
3. Enter credentials for user created in step 1 when prompted.
   Skipping this step will skip checking your Router's config.

## Default targets
By default, the following targets are used for testing:

- Ping: [86.54.11.1](https://joindns4.eu/), [185.222.222.222](https://dns.sb/) and [9.9.9.9](https://quad9.net/).
- DNS: [86.54.11.1](https://joindns4.eu/), [185.222.222.222](https://dns.sb/) and [9.9.9.9](https://quad9.net/) (resolving [mikrotik.com](https://mikrotik.com/)).
- NTP: [ntp.vsl.nl](https://www.vsl.nl/), [ntp.se](https://www.netnod.se/swedish-distributed-time-service) and [times.tu-berlin.de](https://www.tu.berlin/campusmanagement/angebot/zeitserver).
- HTTP: [european-union.europa.eu](https://european-union.europa.eu), [www.qwant.com](https://www.qwant.com/) and [bunny.net](https://bunny.net/).
- HTTPS: Same as HTTP.

These targets have been chosen due to them generally being very stable *and* being *Europe*-based providers.  
I am *NOT* affiliated with any of them, nor did I really ask for their approval.

### Overriding defaults

In case you do not like the defaults, you can override them.  
To do so, create a textfile `overrides.yaml` next to the executable and add the following contents to it:

```yaml
dns:
  servers:
    - 192.168.3.26
    - 192.168.1.250
  host: google.com
icmp:
  servers:
    - 127.0.0.1
    - 192.168.1.2
ntp:
  servers:
    - time.google.com
    - time.cloudflare.com
  # Maximum deviation (in seconds you allow)
  max_deviation: 300
http:
  servers:
    - www.finlaydag33k.nl
    - www.youtube.com
```

## Compiling it yourself

In case I did not compile for your platform or you aren't that keen on running a mystery blob, you can opt to compile this tool yourself.  

TODO: Write proper instructions

1. [Install Crystal](https://crystal-lang.org/install/) for your platform.
2. Clone the repo and cd into it:
   ```
   git clone https://github.com/FinlayDaG33k/Ingraham.git ingraham
   cd ingraham
   ```
3. Install dependencies:
   ```
   shards install
   ```
4. Build:
   ```
   # Without debug symbols (recommended for end-users)
   shards build --release --static --no-debug

   # With debug symbols (recommended for development)
   shards build --release --static
   ```
5. Your binaries will now be in the directory `bin`!