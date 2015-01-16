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
unless success
  puts "Key did not change, may have been the same key or may not have worked."
end
# Switch to staging branch
current_branch = git.current_branch
if git.is_branch?($config[:staging_branch])
  git.checkout($config[:staging_branch])
else
  puts "Staging branch missing or misconfigured"
  abort
end
# Sideload app
success = loader.sideload(root_dir: $config[:repo_dir])
unless success
  puts "Failed to sideload app"
  git.checkout(current_branch)
  abort
end
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
  puts "Signing Failed"
end
# Switch back to orginal branch
git.checkout(current_branch)



