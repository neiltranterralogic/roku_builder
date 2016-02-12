module RokuBuilder
  class Navigator < Util
    def init
      @commands = {
        up: "Up",
        down: "Down",
        right: "Right",
        left: "Left",
        select: "Select",
        back: "Back",
        home: "Home",
        rew: "Rev",
        ff: "Fwd",
        play: "Play",
        replay: "InstantReplay"
      }
    end
    def nav(command:)
      if @commands.has_key?(command)
        conn = Faraday.new(url: "#{@url}:8060") do |f|
          f.request :multipart
          f.request :url_encoded
          f.adapter Faraday.default_adapter
        end

        path = "/keypress/#{@commands[command]}"
        response = conn.post path
        return response.success?
      else
        return false
      end
    end
    def type(text:)
      conn = Faraday.new(url: "#{@url}:8060") do |f|
        f.request :multipart
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end
      text.split(//).each do |c|
        path = "/keypress/LIT_#{CGI::escape(c)}"
        response = conn.post path
        return false unless response.success?
      end
      return true
    end
  end
end
