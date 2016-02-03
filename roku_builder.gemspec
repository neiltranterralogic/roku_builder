# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'roku_builder/version'

Gem::Specification.new do |spec|
  spec.name          = "roku_builder"
  spec.version       = RokuBuilder::VERSION
  spec.authors       = ["greeneca"]
  spec.email         = ["charles.greene@redspace.com"]
  spec.summary       = %q{Build Tool for Roku Apps}
  spec.description   = %q{Allows the user to easily sideload, package, deeplink, test, roku apps.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rubyzip",             "~> 1.1"
  spec.add_dependency "faraday",             "~> 0.9"
  spec.add_dependency "faraday-digestauth",  "~> 0.2"
  spec.add_dependency "git",                 "~> 1.2.9"

  spec.add_development_dependency "bundler",  "~> 1.7"
  spec.add_development_dependency "rake",     "~> 10.0"
  spec.add_development_dependency "byebug",   "~> 3.5"
  spec.add_development_dependency "minitest", "~> 5.8"
end
