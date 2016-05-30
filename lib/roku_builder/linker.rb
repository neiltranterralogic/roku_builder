module RokuBuilder

  # Launch application, sending parameters
  class Linker < Util
    # Deeplink to an app
    # @param options [String] Options string
    # @param app_id [String] Id of the app to launch (defaults to dev)
    # @param logger [Logger] System Logger
    # @note Options string should be formated like the following: "<key>:<value>[, <key>:<value>]*"
    # @note Any options will be accepted and sent to the app
    def launch(options: nil, app_id: "dev")
      path = "/launch/#{app_id}"
      payload = Util.options_parse(options: options)

      unless payload.keys.count > 0
        @logger.warn "No options sent to launched app"
      else
        path = "#{path}?#{parameterize(payload)}"
      end

      conn = multipart_connection(port: 8060)

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
