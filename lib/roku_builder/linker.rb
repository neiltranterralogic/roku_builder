module RokuBuilder
  class Linker < Util
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

    def parameterize(params)
        URI.escape(params.collect{|k,v| "#{k}=#{URI.escape(v, "?&")}"}.join('&'))
    end
  end
end
