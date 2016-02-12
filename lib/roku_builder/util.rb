module RokuBuilder

  # Super class for device utilities
  # This class defines a common initializer and allows subclasses
  # to define their own secondary initializer
  class Util

    # Common initializer of device utils
    # @param ip [String] IP address of roku device
    # @param user [String] Username for roku device
    # @param password [String] Password for roku device
    def initialize(ip:, user:, password:)
      @device_config = {
        ip: ip,
        user: user,
        password: password
      }
      @roku_ip_address = ip
      @dev_username = user
      @dev_password = password
      @url = "http://#{@roku_ip_address}"
      init()
    end

    # Second initializer to be overwriten
    def init
      #Override in subclass
    end
  end
end
