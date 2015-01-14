#!/usr/bin/env ruby
#Side loads channel to roku device through curl.
#author : Seiji Morikami

require "fileutils"
require "date"
require "tempfile"

$roku_ip_address = "192.168.1.127"
$dev_username = "rokudev"
$dev_password = "aaaa"

ARGV.each do|a|
  $roku_ip_address = a
end

puts "packaging to: #{$roku_ip_address}"

#update manifest version.
def roku_update_manifest(path)

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

# side load to roku device with curl
def roku_side_load
  puts "Zipping package..."
  #Dir.chdir(source_root)
  puts "changing folder - " + Dir.pwd

  system("zip -r  pkg.zip \"resources\" >> pkg_log.txt")
  system("zip -r  pkg.zip \"manifest\" >> pkg_log.txt")
  system("zip -r  pkg.zip \"source\" >> pkg_log.txt")
  system("rm pkg_log.txt")
  system("rm pkg.zip.tmp*")
  package_success = false
  package_message = "No package created!"
  puts "Sending package to roku device..."
  package_pipe = IO.popen("curl --anyauth -u \"#{$dev_username}:#{$dev_password}\" --digest -s -S -F \"archive=@pkg.zip\" -F \"mysubmit=Replace\" http://#{$roku_ip_address}/plugin_install")
  while(line = package_pipe.gets)
    if line.include?("Application Received")
      package_message = line 
    end
    if line.include?("Install Success")
      package_success = true
    end
  end
  system("rm pkg.zip")
  system("rm pkg_log.txt")
  puts "Result: " + package_message
end

#roku_update_manifest("#{Dir.pwd}/manifest")
roku_side_load
#gets
