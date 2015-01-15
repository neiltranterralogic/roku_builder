module RokuBuilder
  class Util

    def initialize(ip:, user:, password:)
      $roku_ip_address = ip
      $dev_username = user
      $dev_password = password
      $url = "http://#{$roku_ip_address}"
    end

  end
end
