module RokuBuilder

  # Super class for device utilities
  # This class defines a common initializer and allows subclasses
  # to define their own secondary initializer
  class Util

    # Common initializer of device utils
    # @param ip [String] IP address of roku device
    # @param user [String] Username for roku device
    # @param password [String] Password for roku device
    def initialize(ip:, user:, password:, logger:)
      @device_config = {
        ip: ip,
        user: user,
        password: password
      }
      @roku_ip_address = ip
      @dev_username = user
      @dev_password = password
      @url = "http://#{@roku_ip_address}"
      @logger = logger
      init()
    end

    # Second initializer to be overwriten
    def init
      #Override in subclass
    end

    def simple_connection
      Faraday.new(url: @url) do |f|
        f.request :digest, @dev_username, @dev_password
        f.adapter Faraday.default_adapter
      end
    end

    def multipart_connection(port: nil)
      url = @url
      url = "#{url}:#{port}" if port
      Faraday.new(url: url) do |f|
        f.headers['Content-Type'] = Faraday::Request::Multipart.mime_type
        f.request :digest, @dev_username, @dev_password
        f.request :multipart
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end
    end
  end
end
