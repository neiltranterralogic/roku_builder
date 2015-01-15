#!/usr/bin/env ruby

require "bundler"
require "faraday"
require "faraday/digestauth"

class RokuKeyer

  def initialize(ip, user, password)
    $roku_ip_address = ip
    $dev_username = user
    $dev_password = password
    $url = "http://#{$roku_ip_address}"
  end

  def rekey(keyed_pkg, password)
    oldId = currentDevId

    path = "/plugin_inspect"
    conn = Faraday.new(url: $url) do |f|
      f.request :digest, $dev_username, $dev_password
      f.request :multipart
      f.request :url_encoded
      f.adapter Faraday.default_adapter
    end
    payload =  {
      mysubmit: "Rekey",
      passwd: password,
      archive: Faraday::UploadIO.new(keyed_pkg, 'application/octet-stream')
    }
    response = conn.post path, payload

    newId = currentDevId

    newId != oldId
  end

  private

  def currentDevId
    path = "/plugin_package"
    conn = Faraday.new(url: $url) do |f|
      f.request :digest, $dev_username, $dev_password
      f.adapter Faraday.default_adapter
    end
    response = conn.get path

    /Your Dev ID:\s*<font[^>]*>([^<]*)<\/font>/.match(response.body)[1]

  end
end
