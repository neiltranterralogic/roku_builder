#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), "lib")


require "roku_builder"

# Copy config.rb.example to config.rb and add config values
require_relative "./config"

keyer = RokuBuilder::Keyer.new(**$config)

puts "Dev Id: #{keyer.dev_id}"

puts "Did rekey: #{keyer.rekey(**$rekey_config)}"

loader = RokuBuilder::Loader.new(**$config)

puts "Did sideload: #{loader.sideload(**$sideload_config)}"
