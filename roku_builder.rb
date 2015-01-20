#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), "lib")

require "byebug"
require "roku_builder"
require "optparse"

options = {}
options[:config] = '~/.roku_config.rb'
options[:stage] = 'production'
options[:app_name] = 'Roku App'

OptionParser.new do |opts|
  opts.banner = "Usage: roku <command> [options]"

  opts.on("-l", "--sideload", "Command: Sideload an app") do |s|
    options[:sideload] = s
  end

  opts.on("-p", "--package", "Command: Package an app") do |p|
    options[:package] = p
  end

  opts.on("-t", "--test", "Command: Test an app") do |t|
    options[:test] = t
  end

  opts.on("-s", "--stage STAGE", "Set the stage to use. Default: 'production'") do |b|
    options[:stage] = b
    options[:set_stage] = true
  end

  opts.on("-n", "--app_name NAME", "Set the app name for packaging. Default: 'Roku App'") do |n|
    options[:app_name] = n
  end

  opts.on("-c", "--config CONFIG", "Set a custom config file. Default: '~/.roku_config.rb'") do |c|
    options[:config] = c
  end

  opts.on("-h", "--help", "Show this message") do |h|
    puts opts
    exit
  end
end.parse!

commands = 0
commands += 1 if options[:sideload]
commands += 1 if options[:package]
commands += 1 if options[:test]

if commands > 1
  puts "Only one command is allowed"
  abort
end
if commands < 1
  puts "A command is required"
  abort
end

# load config
config_file = File.expand_path(options[:config])
unless File.exists?(config_file)
  puts "Missing config file: #{config_file}"
  abort
end
load config_file

# setup configs
device_config = $config[:device_info]
stage = options[:stage].to_sym
sideload_config = {
  root_dir: $config[:repo_dir],
  branch: $config[stage][:branch],
  update_manifest: false
}

if options[:sideload]
  ### Sideload App ###
  loader = RokuBuilder::Loader.new(**device_config)
  success = loader.sideload(**sideload_config)
  puts "FATAL: Failed to sideload app" unless success
elsif options[:package]
  ### Package App ###
  stage_config = $config[stage]
  keyer = RokuBuilder::Keyer.new(**device_config)
  loader = RokuBuilder::Loader.new(**device_config)
  packager = RokuBuilder::Packager.new(**device_config)
  # Key Roku
  success = keyer.rekey(**stage_config[:key])
  puts "WARNING: Key did not change" unless success
  # Sideload App
  sideload_config[:update_manifest] = true
  build_version = loader.sideload(**sideload_config)
  unless build_version
    puts "FATAL: Failed to sideload app"
    abort
  end
  # Package App
  package_config = {
    app_name_version: "#{options[:app_name]} - #{build_version}",
    password: stage_config[:key][:password],
    out_file: File.join("/tmp", "#{stage}_#{build_version}.pkg")
  }
  success = packager.package(**package_config)
  if success
    puts "Signing Successful: #{package_config[:out_file]}"
  else
    puts "FATAL: Signing Failed"
  end
elsif options[:test]
  ### Test App ###
end
