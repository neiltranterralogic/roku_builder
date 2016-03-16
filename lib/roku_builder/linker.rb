module RokuBuilder

  # Launch application, sending parameters
  class Linker < Util
    # Deeplink to the currently sideloaded app
    # @param options [String] Options string
    # @note Options string should be formated like the following: "<key>:<value>[, <key>:<value>]*"
    # @note Any options will be accepted and sent to the app
    def link(options:)
      path = "/launch/dev"
      payload = {}
      return false unless options
      opts = options.split(/,\s*/)
      opts.each do |opt|
        opt = opt.split(":")
        key = opt.shift.to_sym
        value = opt.join(":")
        payload[key] = value
      end

      unless payload.keys.count > 0
        return false
      end

      path = "#{path}?#{parameterize(payload)}"
      conn = Faraday.new(url: "#{@url}:8060") do |f|
        f.request :digest, @dev_username, @dev_password
        f.request :multipart
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end

      response = conn.post path
      return response.success?
    end

    private

    # Parameterize options to be sent to the app
    # @param params [Hash] Parameters to be sent
    # @return [String] Parameters as a string, URI escaped
    def parameterize(params)
      params.collect{|k,v| "#{k}=#{CGI.escape(v)}"}.join('&')
    end
  end
end
