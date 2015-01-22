module RokuBuilder
  class Packager < Util

    # Sign and download the currently sideloaded app
    # Params:
    # +app_name_version+:: the name and version of the package
    # +out_file+:: location to download signed package to
    # +password+:: password for the devices current key
    # Returns:
    # +boolean+:: true on package success and download, false otherwise
    def package(app_name_version:, out_file:, password:)
      # Sign package
      path = "/plugin_package"
      conn = Faraday.new(url: @url) do |f|
        f.headers['Content-Type'] = Faraday::Request::Multipart.mime_type
        f.request :digest, @dev_username, @dev_password
        f.request :multipart
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end
      payload =  {
        mysubmit: "Package",
        app_name: app_name_version,
        passwd: password,
        pkg_time: Time.now.to_i
      }
      response = conn.post path, payload

      # Check for error
      failed = /(Failed: [^\.]*\.)/.match(response.body)
      return failed[1] if failed

      # Download signed package
      pkg = /<a href="pkgs[^>]*>([^<]*)</.match(response.body)[1]
      path = "/pkgs/#{pkg}"
      conn = Faraday.new(url: @url) do |f|
        f.request :digest, @dev_username, @dev_password
        f.adapter Faraday.default_adapter
      end
      response = conn.get path
      return false if response.status != 200

      File.open(out_file, 'w+') {|fp| fp.write(response.body)}
      true
    end
  end
end
