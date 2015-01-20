#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), "lib")

require "byebug"
require "git"
require "roku_builder"

# Copy config.rb.example to config.rb and add config values
require_relative "./config"

config = $config[:device_info]

### Deploy Staging ###
# Setup Utils
keyer = RokuBuilder::Keyer.new(**config)
loader = RokuBuilder::Loader.new(**config)
packager = RokuBuilder::Packager.new(**config)
git = Git.open($config[:repo_dir])
# Key with dev key
success = keyer.rekey(**$config[:dev_key])
puts "WARNING: Key did not change" unless success
# Sideload app
sideload_config = {
 root_dir: $config[:repo_dir],
 branch: $config[:staging][:branch]
}
success = loader.sideload(**sideload_config)
puts "FATAL: Failed to sideload app" unless success
# Package app
package_config = {
  app_name_version: "Test Staging App",
  password: $config[:dev_key][:password]
}
file = Tempfile.new('signed_pkg_')
package_config[:out_file] = "#{file.path}.pkg"
file.unlink

success = packager.package(**package_config)
if success
  puts "Signing Successful: #{package_config[:out_file]}"
else
  puts "FATAL: Signing Failed"
end



