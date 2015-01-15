module RokuBuilder
  class Keyer < Util

    def rekey(keyed_pkg:, password:)
      oldId = dev_id

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

      newId = dev_id

      newId != oldId
    end

    def dev_id
      path = "/plugin_package"
      conn = Faraday.new(url: $url) do |f|
        f.request :digest, $dev_username, $dev_password
        f.adapter Faraday.default_adapter
      end
      response = conn.get path

      /Your Dev ID:\s*<font[^>]*>([^<]*)<\/font>/.match(response.body)[1]

    end
  end
end
