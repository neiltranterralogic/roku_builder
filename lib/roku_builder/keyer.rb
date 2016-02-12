module RokuBuilder
  class Keyer < Util

    # Sets the key on the roku device
    # Params:
    # +keyed_pkg+:: a package that has be keyed with the desired key
    # +password+:: password for the desired key
    # Returns:
    # +boolean+:: true if key changed, false otherwise
    def rekey(keyed_pkg:, password:)
      oldId = dev_id

      # upload new key with password
      path = "/plugin_inspect"
      conn = Faraday.new(url: @url) do |f|
        f.request :digest, @dev_username, @dev_password
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

      # check key
      newId = dev_id
      newId != oldId
    end

    # get the current developer id
    def dev_id
      path = "/plugin_package"
      conn = Faraday.new(url: @url) do |f|
        f.request :digest, @dev_username, @dev_password
        f.adapter Faraday.default_adapter
      end
      response = conn.get path

      dev_id = /Your Dev ID:\s*<font[^>]*>([^<]*)<\/font>/.match(response.body)
      if dev_id
        dev_id = dev_id[1]
      else
        dev_id = /Your Dev ID:[^>]*<\/label> ([^<]*)/.match(response.body)[1]
      end
      dev_id
    end
  end
end
