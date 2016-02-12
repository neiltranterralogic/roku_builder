module RokuBuilder
  class Deployer

    @conn = nil
    @email = nil
    @password = nil
    @app_id = nil
    @firmware = nil

    def initialize(email:, password:, app_id:, firmware:)
      @email = email
      @password = password
      @app_id = app_id
      @firmware = firmware
    end

    def stage(package:, version:)
      unless @conn
        login()
      end
      upload(package: package, version: version)
    end

    def login()
      url = "https://owner.roku.com"
      conn = Faraday.new(url: url, ssl: {verify: false}) do |f|
        f.use :cookie_jar
        f.request :multipart
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end
      payload = {
        "Email" => @email,
        "Password" => @password,
        "RememberMe" => false
      }
      resp = conn.post "/Login", payload

      if resp.status == 200 or resp.status == 302
        @conn = conn
        return true
      end
      return false
    end

    private

    def upload(package:, version:)
      if @conn
        path = "/Developer/Apps/SavePackage/#{@app_id}"

        resp = @conn.get path
        page = Nokogiri::HTML(resp.body)
        puts "=============================================================="
        puts resp.body
        puts "=============================================================="
        byebug
        token = page.css('input[name="__RequestVerificationToken"]')[0].value

        payload = {
          "Unpublished.Version" => version,
          "Unpublished.MinFirmwareRevision" => @firmware,
          "AppUpload" => Faraday::UploadIO.new(package, 'application/octet-stream'),
          "__RequestVerificationToken" => token
        }
        resp = @conn.post path, payload


        return false unless resp.status == 200

        path = "/Developer/Apps/Package/#{@app_id}"
        resp = @conn.get path


        page  = Nokogiri::HTML(resp.body)
        links = page.css('#viewPackage a')
        link = nil
        links.each do |l|
          if l.href =~ /\/add\//
            link = l
            break
          end
        end
        link.text
      end
    end

    def publish(conn:, app_id:)

    end
  end
end
