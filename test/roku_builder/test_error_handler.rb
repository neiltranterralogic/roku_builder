# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"
module RokuBuilder
  class ErrorHandler
    class << self
      def abort
        #do nothing
      end
    end
  end

  class ErrorHandlerTest < Minitest::Test
    def test_handle_error_codes
      error_groups = {
        fatal: {
        options_code: [
          EXTRA_COMMANDS,
          NO_COMMANDS,
          EXTRA_SOURCES,
          NO_SOURCE,
          BAD_CURRENT,
          BAD_IN_FILE
      ],
        configure_code:[
          CONFIG_OVERWRITE,
      ],
      device_code: [
        BAD_DEVICE,
        NO_DEVICES,
      ],
      load_code: [
        MISSING_CONFIG,
        INVALID_CONFIG,
        MISSING_MANIFEST,
        UNKNOWN_DEVICE,
        UNKNOWN_PROJECT,
        UNKNOWN_STAGE,
        BAD_PROJECT_DIR,
        BAD_KEY_FILE
      ],
        command_code: [
          FAILED_SIDELOAD,
          FAILED_SIGNING,
          FAILED_DEEPLINKING,
          FAILED_NAVIGATING,
          FAILED_SCREENCAPTURE,
          MISSING_MANIFEST,
          BAD_PRINT_ATTRIBUTE
      ],
        configs_code: [
          MISSING_OUT_FOLDER
      ]
      },
        info: {
        device_code: [
          CHANGED_DEVICE
      ],
        configure_code:[
          SUCCESS
      ]
      },
        warn: {
        load_code: [
          DEPRICATED_CONFIG
      ]
      },
        debug: {
        configs_code: [
          VALID
      ]
      }
      }
      error_groups.each_pair do |type,errors|
        errors.each_pair do |key,value|
          value.each do |code|
            logger = Minitest::Mock.new
            options = {logger: logger}
            options[:options] = {deeplink_depricated: true} if key == :load_code or key == :options_code
            options[key] = code
            logger.expect(type, nil)  {|string| string.class == String}
            method = "handle_#{key}s"
            ErrorHandler.send(method.to_sym, **options)
            logger.verify
          end
        end
      end
    end
  end
end
