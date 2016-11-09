# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder

  # Collects information on a package for submission
  class Inspector < Util

    # Inspects the given pkg
    # @param pkg [String] Path to the pkg to be inspected
    # @param password [String] Password for the given pkg
    # @return [Hash] Package information. Contains the following keys:
    #   * app_name
    #   * dev_id
    #   * creation_date
    #   * dev_zip
    def inspect(pkg:, password:)

      # upload new key with password
      path = "/plugin_inspect"
      conn = multipart_connection
      payload =  {
        mysubmit: "Inspect",
        passwd: password,
        archive: Faraday::UploadIO.new(pkg, 'application/octet-stream')
      }
      response = conn.post path, payload

      app_name = /App Name:\s*<\/td>\s*<td>\s*<font[^>]*>([^<]*)<\/font>\s*<\/td>/.match(response.body)
      dev_id = nil
      creation_date = nil
      dev_zip = nil
      if app_name
        app_name = app_name[1]
        dev_id = /Dev ID:\s*<\/td>\s*<td>\s*<font[^>]*>([^<]*)<\/font>\s*<\/td>/.match(response.body)[1]
        creation_date = /new Date\(([^)]*)\)/.match(response.body.delete("\n"))[1]
        dev_zip = /dev.zip:\s*<\/td>\s*<td>\s*<font[^>]*>([^<]*)<\/font>\s*<\/td>/.match(response.body)[1]
      else
        app_name = /App Name:[^<]*<div[^>]*>([^<]*)<\/div>/.match(response.body)[1]
        dev_id = /Dev ID:[^<]*<div[^>]*><font[^>]*>([^<]*)<\/font><\/div>/.match(response.body)[1]
        creation_date = /new Date\(([^\/]*)\)/.match(response.body.delete("\n"))[1]
        dev_zip = /dev.zip:[^<]*<div[^>]*><font[^>]*>([^<]*)<\/font><\/div>/.match(response.body)[1]
      end

      return {app_name: app_name, dev_id: dev_id, creation_date: Time.at(creation_date.to_i).to_s, dev_zip: dev_zip}

    end

    # Capture a screencapture for the currently sideloaded app
    # @return [Boolean] Success
    def screencapture(out_folder:, out_file: nil)
      path = "/plugin_inspect"
      conn = multipart_connection
      payload =  {
        mysubmit: "Screenshot",
        passwd: @dev_password,
        archive: Faraday::UploadIO.new("/dev/null", 'application/octet-stream')
      }
      response = conn.post path, payload

      path = /<img src="([^"]*)">/.match(response.body)
      return false unless path
      path = path[1]
      unless out_file
        out_file = /time=([^"]*)">/.match(response.body)
        out_file = "dev_#{out_file[1]}.jpg" if out_file
      end

      conn = simple_connection

      response = conn.get path

      File.open(File.join(out_folder, out_file), "w") do |io|
        io.write(response.body)
      end
      @logger.info "Screen captured to #{File.join(out_folder, out_file)}"
      return response.success?
    end

    # Capture a gifcapture of the currently sideloaded app
    # @param length [Integer] length in seconds of the animation
    # @param out_folder [String] folder to save the animation to
    # @param out_file [String] filename to save animation as (default: animation.gif)
    # @param actions [String] comma seperated actions (should be integers or device commands)
    # @return [Boolean] Success
    def gifcapture(length:, out_folder:, out_file: nil, actions:)
      fps = 15
      delay = 2000
      frame_count = length * fps
      frames = Array.new(frame_count)
      bad_frames = []

      running = true
      while running
        start_time = Time.now
        actions_thread = Thread.new("#{delay},#{actions}", @device_config) { |actions,config|
          @logger.debug("Start actions: "+actions)
          navigator = Navigator.new(**config)
          actions = actions.split(",")
          @logger.debug("Action Count: #{actions.count}")
          while actions.count > 0
            sleep_time = 0.0
            while actions.count > 0 and actions[0].to_i.to_s == actions[0]
              sleep_time += actions.shift.to_i
            end
            @logger.debug("Sleeping: #{sleep_time/1000}")
            sleep sleep_time/1000
            commands = []
            while actions.count > 0 and actions[0].to_i.to_s != actions[0]
              commands.push(actions.shift.to_sym)
            end
            @logger.debug("Navigating: #{commands.join(", ")}")
            navigator.nav(commands: commands)
          end
        }
        while Time.now - start_time < length
          filename = "capture_#{Time.now.to_i}.jpg"
          if screencapture(out_folder: out_folder, out_file: filename)
            frame_timestamp = Time.now
            frame_num = ((frame_timestamp-start_time-(delay/1000.0)) * fps).to_i + fps
            @logger.debug("Frame: #{frame_num}")
            if frames[frame_num]
              bad_frames.push(File.join(out_folder, filename))
            else
              frames[frame_num] = File.join(out_folder, filename)
            end
          end
        end
        if frames.uniq.count >= frame_count*0.8
          running = false
        else
          @logger.info ("#{frames.uniq.count} of #{frame_count} frames")
          @logger.unknown("Return to animation start position. Press Enter when ready")
          gets
          delay -= 1000/fps
        end
        actions_thread.join
      end


      @logger.debug("Removeing bad frames")
      bad_frames.each {|file| FileUtils.rm(file)} if bad_frames.count > 0

      if frames.count > 0
        out_file = "anim_#{Time.now.to_i}.gif" unless out_file
        out = File.join(out_folder, out_file)

        @logger.info("Generating Animation")
        animation = ImageList.new(*frames)
        animation.delay = 10
        animation.write(out)

        @logger.debug("Removeing frames")
        frames.each {|file| FileUtils.rm(file)}
        true
      else
        false
      end
    end
  end
end
