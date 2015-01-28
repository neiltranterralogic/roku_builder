module RokuBuilder
  class Util

    # Common initializer of device utils
    # Params:
    # +ip+:: IP address of roku device
    # +user+:: username for roku device
    # +password+:: password for roku device
    def initialize(ip:, user:, password:)
      @roku_ip_address = ip
      @dev_username = user
      @dev_password = password
      @url = "http://#{@roku_ip_address}"
      init()
    end

    def init
      #Override in subclass
    end
  end
end
