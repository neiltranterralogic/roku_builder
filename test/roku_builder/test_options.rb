# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class OptionsTest < Minitest::Test
    def test_options_validate_extra_commands
      options = {
        sideload: true,
        package: true
      }
      assert_raises InvalidOptions do
        build_options(options)
      end
    end
    def test_options_validate_no_commands
      options = {}
      assert_raises InvalidOptions do
        build_options(options)
      end
    end
    def test_options_validate_extra_sources_sideload
      options = {
        sideload: true,
        working: true,
        current: true
      }
      assert_raises InvalidOptions do
        build_options(options)
      end
    end
    def test_options_validate_working
      options = {
        sideload: true,
        working: true
      }
      build_options(options)
    end
    def test_options_validate_no_source
      options = {
        package: true
      }
      assert_raises InvalidOptions do
        build_options(options)
      end
    end
    def test_options_validate_bad_current
      options = {
        package: true,
        current: true
      }
      assert_raises InvalidOptions do
        build_options(options)
      end
    end
    def test_options_validate_bad_in
      options = {
        package: true,
        in: true
      }
      assert_raises InvalidOptions do
        build_options(options)
      end
    end
    def test_options_validate_depricated
      options = {
        deeplink: "a:b c:d",
        deeplink_depricated: true
      }
      build_options(options)
    end
    def test_options_validate_current
      options = {
        sideload: true,
        current: true
      }
      build_options(options)
    end
    def test_options_validate_extra_sources_package
      options = {
        package: true,
        in: "",
        set_stage: true
      }
      assert_raises InvalidOptions do
        build_options(options)
      end
    end
    def test_options_exclude_command_package
      options = build_options({
        package:true,
        set_stage: true
      })
      assert options.exclude_command?
    end
    def test_options_exclude_command_build
      options = build_options({
        build:true,
        set_stage: true
      })
      assert options.exclude_command?
    end
    def test_options_exclude_command_sideload
      options = build_options({
        sideload:true,
        set_stage: true
      })
      refute options.exclude_command?
    end
    def test_options_source_command_sideload
      options = build_options({
        sideload:true,
        working: true
      })
      assert options.source_command?
    end
    def test_options_source_command_deeplink
      options = build_options({
        deeplink: true,
      })
      refute options.source_command?
    end
    def test_options_command
      options = build_options({
        deeplink: true,
      })
      assert_equal :deeplink, options.command
    end
    def test_options_device_command_true
      options = build_options({
        deeplink: true,
      })
      assert options.device_command?
    end
    def test_options_device_command_false
      options = build_options({
        build: true,
        working: true
      })
      refute options.device_command?
    end
    def test_options_has_source_false
      options = build_options({
        deeplink: true,
      })
      refute options.has_source?
    end
    def test_options_has_source_true
      options = build_options({
        deeplink: true,
        working: true
      })
      assert options.has_source?
    end
  end
end
