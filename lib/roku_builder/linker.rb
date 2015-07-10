module RokuBuilder
  class Linker < Util
    def link(options)
      path = "/launch/dev"
      payload = options
      if options.has_key?(:content_type) and options.has_key?(:mgid)
        payload[:entity] = options[:content_type]
        payload[:mgid] = options[:mgid]
        payload[:autoplay] = false
      end
      path = "#{path}?#{parameterize(payload)}"
      conn = Faraday.new(url: "#{@url}:8060") do |f|
        f.request :digest, @dev_username, @dev_password
        f.request :multipart
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end

      response = conn.post path
    end

    private

    def parameterize(params)
        URI.escape(params.collect{|k,v| "#{k}=#{URI.escape(v, "?&")}"}.join('&'))
    end
  end
end
