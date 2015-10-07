module RokuBuilder
  class Inspector < Util

    # Inspects the given pkg
    # Params:
    # +pkg+:: a package that has be keyed with the desired key
    # +password+:: password for the desired key
    # Returns:
    # +hash+:: information on the package
    def inspect(pkg:, password:)

      # upload new key with password
      path = "/plugin_inspect"
      conn = Faraday.new(url: @url) do |f|
        f.request :digest, @dev_username, @dev_password
        f.request :multipart
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end
      payload =  {
        mysubmit: "Inspect",
        passwd: password,
        archive: Faraday::UploadIO.new(pkg, 'application/octet-stream')
      }
      response = conn.post path, payload

      app_name = /App Name:\s*<\/td>\s*<td>\s*<font[^>]*>([^<]*)<\/font>\s*<\/td>/.match(response.body)[1]
      dev_id = /Dev ID:\s*<\/td>\s*<td>\s*<font[^>]*>([^<]*)<\/font>\s*<\/td>/.match(response.body)[1]
      creation_date = /Creation Date:\s*<\/td>\s*<td>\s*<font[^>]*>\s*<script[^>]*>\s*var d = new Date\(([^\)]*)\)[^<]*<\/script><\/font>\s*<\/td>/.match(response.body.gsub("\n", ''))[1]
      dev_zip = /dev.zip:\s*<\/td>\s*<td>\s*<font[^>]*>([^<]*)<\/font>\s*<\/td>/.match(response.body)[1]

      return {app_name: app_name, dev_id: dev_id, creation_date: Time.at(creation_date.to_i).to_s, dev_zip: dev_zip}

    end
  end
end
