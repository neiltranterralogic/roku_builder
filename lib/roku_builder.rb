# ********** Copyright 2016 Viacom, Inc. Apache 2.0 **********

require "logger"
require "faraday"
require "faraday/digestauth"
require "pathname"
#controller
require "net/ping"
#loader
require "net/telnet"
require "fileutils"
require "tempfile"
require "tmpdir"
require "zip"
require "git"
#config_manager
require 'json'
#stager
require 'pstore'
#profiler
require 'nokogiri'
#navigator
require 'io/console'
#monitor
require 'readline'


require 'roku_builder/util'
Dir.glob(File.join(File.dirname(__FILE__), "roku_builder", "*")).each do |path|
  file = "roku_builder/"+File.basename(path, ".rb")
  require file unless file == "roku_builder/util"
end

module RokuBuilder

  ### Global Codes ###

  # Success
  SUCCESS         = 0

  ### Validation Codes ###

  # Valid Options
  VALID           = 0

  # Too many commands given
  EXTRA_COMMANDS  = 1

  # No commands given
  NO_COMMANDS     = 2

  # Too many source options given
  EXTRA_SOURCES   = 3

  # No source options given
  NO_SOURCE       = 4

  # Incorrect use of current option
  BAD_CURRENT     = 5

  # No deeplink options supplied for deeplink
  # BAD_DEEPLINK    = 6

  # Incorrect use of the in option
  BAD_IN_FILE     = 7

  # An Option is Depricated
  DEPRICATED      = 8



  ### Device Codes ###

  # The default device is offline switched to a secondary device
  CHANGED_DEVICE = -1

  # Device is online
  GOOD_DEVICE = 0

  # User defined device was not online
  BAD_DEVICE = 1

  # No configured devices were online
  NO_DEVICES = 2


  ### Execute Codes ###

  # Config has deplicated options
  DEPRICATED_CONFIG  = -1

  # Tring to overwrite existing config file
  CONFIG_OVERWRITE   = 1

  # Missing config file
  MISSING_CONFIG     = 2

  # Invalid config file
  INVALID_CONFIG     = 3

  # Missing manifest file
  MISSING_MANIFEST   = 4

  # Unknow device given
  UNKNOWN_DEVICE     = 5

  # Unknown project given
  UNKNOWN_PROJECT    = 6

  # Unknown stage given
  UNKNOWN_STAGE      = 7

  # Missing out folder
  MISSING_OUT_FOLDER = 8

  # Bad Project Directory
  BAD_PROJECT_DIR = 9

  # Bad Key File
  BAD_KEY_FILE = 10


  ### Execute Codes ###

  # Failed to sideload app
  FAILED_SIDELOAD    = 8

  # Failed to sign app
  FAILED_SIGNING     = 9

  # Failed to deeplink to app
  FAILED_DEEPLINKING = 10

  # Failed to send navigation command
  FAILED_NAVIGATING  = 11

  # Failed to capture screen
  FAILED_SCREENCAPTURE = 12

  # Did not sideload as content is identical
  IDENTICAL_SIDELOAD = 13

  # Bad print attribute
  BAD_PRINT_ATTRIBUTE = 14
end

class ::String
  def underscore!
    word = self
    word.gsub!(/::/, '/')
    word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
    word.tr!("-", "_")
    word.downcase!
    nil
  end

  def underscore
    word = self.dup
    word.underscore!
    word
  end
end

class ::Hash
  def deep_merge(second)
    merger = proc { |_key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2  }
    self.merge(second, &merger)
  end
end

module Git
  class Stashes
    def pop(index=nil)
      @base.lib.stash_pop(index)
    end
    def drop(index=nil)
      @base.lib.stash_drop(index)
    end
  end
  class Lib
    def stash_pop(id = nil)
      if id
        command('stash pop', [id])
      else
        command('stash pop')
      end
    end
    def stash_drop(id = nil)
      if id
        command('stash drop', [id])
      else
        command('stash drop')
      end
    end
  end
end
