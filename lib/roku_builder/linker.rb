module RokuBuilder
  class Linker < Util
    def link(mgid:, content_type:)
      path = "/launch/dev"
      payload = {
        entity: content_type,
        mgid: mgid,
        autoplay: false
      }
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
        URI.escape(params.collect{|k,v| "#{k}=#{v}"}.join('&'))
    end
  end
end
