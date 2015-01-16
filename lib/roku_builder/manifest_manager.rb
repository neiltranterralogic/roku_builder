module RokuBuilder
  class ManifestManager

    #update manifest version.
    def self.update_build(path)

      build_version = ""

      temp_file = Tempfile.new('manifest')
      begin
        File.open(path, 'r') do |file|
          file.each_line do |line|
            if line.include?("build_version")

              #Update build version.
              build_version = line.split(".")
              iteration = 0
              if 2 == build_version.length
                iteration = build_version[1].to_i + 1
                build_version[0] = Time.now.strftime("%m%d%y")
                build_version[1] = iteration
                build_version = build_version.join(".")
              else
                #Use current date.
                build_version = Time.now.strftime("%m%d%y")+".1"
              end
              temp_file.puts "build_version=#{build_version}" 

            elsif line.include?("title=") and not line.include?("subtitle=")

              if 0 < build_version.length

                #Add build version to title.
                title = line.split("-")
                title[1] = build_version
                temp_file.puts title.join("-")

              end

            else
              temp_file.puts line
            end
          end
        end
        temp_file.rewind
        FileUtils.cp(temp_file.path, path)
      ensure
        temp_file.close
        temp_file.unlink
      end
    end
  end
end
