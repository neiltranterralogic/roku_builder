require "logger"
require "faraday"
require "faraday/digestauth"
#controller
require "net/ping"
#loader
require "net/telnet"
require "fileutils"
require "tempfile"
require "zip"
require "git"
#config_manager
require 'json'

require "roku_builder/controller"
require "roku_builder/util"
require "roku_builder/keyer"
require "roku_builder/inspector"
require "roku_builder/loader"
require "roku_builder/packager"
require "roku_builder/linker"
require "roku_builder/tester"
require "roku_builder/manifest_manager"
require "roku_builder/config_manager"
require "roku_builder/navigator"
require "roku_builder/monitor"
require "roku_builder/version"

# Wrapping module for the Roku Builder Gem
module RokuBuilder
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
  BAD_DEEPLINK    = 6

  # Incorrect use of the in option
  BAD_IN_FILE     = 7



  ### Device Codes ###

  # The default device is offline switched to a secondary device
  CHANGED_DEVICE = -1

  # Device is online
  GOOD_DEVICE = 0

  # User defined device was not online
  BAD_DEVICE = 1

  # No configured devices were online
  NO_DEVICES = 2



  ### Run Codes ###

  # Config has deplicated options
  DEPRICATED_CONFIG  = -1

  # Valid config
  SUCCESS            = 0

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
end
