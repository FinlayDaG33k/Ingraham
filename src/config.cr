require "yaml"

module Ingraham
  class DnsSettings
    include YAML::Serializable

    property servers : Array(String) = ["86.54.11.1", "185.222.222.222", "9.9.9.9"]
    property host : String = "mikrotik.com"

    def initialize
    end
  end

  class IcmpSettings
    include YAML::Serializable

    property servers : Array(String) = ["86.54.11.1", "185.222.222.222", "9.9.9.9"]

    def initialize
    end
  end

  class HttpSettings
    include YAML::Serializable

    property servers : Array(String) = ["european-union.europa.eu", "www.qwant.com", "bunny.net"]

    def initialize
    end
  end
  
  class TesterSettings
    include YAML::Serializable

    property dns : DnsSettings = DnsSettings.new
    property icmp : IcmpSettings = IcmpSettings.new
    property http : HttpSettings = HttpSettings.new

    def initialize
    end
  end

  def self.load_config()
    # Parse Yaml file if it exists or create with defaults
    config = nil
    if File.exists?("overrides.yaml")
      config = TesterSettings.from_yaml(File.read("overrides.yaml"))
    else
      config = TesterSettings.new
    end
  end
end