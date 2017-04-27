# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

class ControllerTest < Minitest::Test
  def test_controller_validate_options_extra_commands
    options = {
      sideload: true,
      package: true
    }
    assert_equal RokuBuilder::EXTRA_COMMANDS, RokuBuilder::Controller.send(:validate_options, {options: options})
  end
  def test_controller_validate_options_no_commands
    options = {}
    assert_equal RokuBuilder::NO_COMMANDS,  RokuBuilder::Controller.send(:validate_options, {options: options})
  end
  def test_controller_validate_options_extra_sources_sideload
    options = {
      sideload: true,
      working: true,
      current: true
    }
    assert_equal RokuBuilder::EXTRA_SOURCES, RokuBuilder::Controller.send(:validate_options, {options: options})
  end
  def test_controller_validate_options_working
    options = {
      sideload: true,
      working: true
    }
    assert_equal RokuBuilder::VALID, RokuBuilder::Controller.send(:validate_options, {options: options})
  end
  def test_controller_validate_options_no_source
    options = {
      package: true
    }
    assert_equal RokuBuilder::NO_SOURCE, RokuBuilder::Controller.send(:validate_options, {options: options})
  end
  def test_controller_validate_options_bad_current
    options = {
      package: true,
      current: true
    }
    assert_equal RokuBuilder::BAD_CURRENT, RokuBuilder::Controller.send(:validate_options, {options: options})
  end
  def test_controller_validate_options_bad_in
    options = {
      package: true,
      in: true
    }
    assert_equal RokuBuilder::BAD_IN_FILE, RokuBuilder::Controller.send(:validate_options, {options: options})
  end
  def test_controller_validate_options_depricated
    options = {
      deeplink: "a:b c:d",
      deeplink_depricated: true
    }
    assert_equal RokuBuilder::DEPRICATED, RokuBuilder::Controller.send(:validate_options, {options: options})
  end
  def test_controller_validate_options_current
    options = {
      sideload: true,
      current: true
    }
    assert_equal RokuBuilder::VALID, RokuBuilder::Controller.send(:validate_options, {options: options})
  end
  def test_controller_validate_options_extra_sources_package
    options = {
      package: true,
      in: "",
      set_stage: true
    }
    assert_equal RokuBuilder::EXTRA_SOURCES, RokuBuilder::Controller.send(:validate_options, {options: options})
  end
  def test_controller_configure
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)
    assert !File.exist?(target_config)

    options = {
      configure: true,
      config: target_config,
    }

    code = RokuBuilder::Controller.send(:configure, {options: options, logger: logger})

    assert File.exist?(target_config)

    options = {
      configure: true,
      config: target_config,
      edit_params: "ip:111.222.333.444"
    }

    code = RokuBuilder::Controller.send(:configure, {options: options, logger: logger})

    assert File.exist?(target_config)
    config = RokuBuilder::Config.new(options: options)
    config.load
    assert_equal "111.222.333.444", config.raw[:devices][config.raw[:devices][:default]][:ip]

    options = {
      configure: true,
      config: target_config
    }

    code = RokuBuilder::Controller.send(:configure, {options: options, logger: logger})

    assert_equal RokuBuilder::CONFIG_OVERWRITE, code

    File.delete(target_config) if File.exist?(target_config)
  end

  def test_controller_check_devices
    logger = Logger.new("/dev/null")
    ping = Minitest::Mock.new
    options = {sideload: true, device_given: false}
    raw = {
      devices: {
        a: {ip: "2.2.2.2"},
        b: {ip: "3.3.3.3"}
      }
    }
    parsed = {
      device_config: {ip: "1.1.1.1"}
    }
    config = RokuBuilder::Config.new(options: options)
    config.instance_variable_set(:@config, raw)
    config.instance_variable_set(:@parsed, parsed)

    Net::Ping::External.stub(:new, ping) do

      ping.expect(:ping?, true, [parsed[:device_config][:ip], 1, 0.2, 1])
      code, ret = RokuBuilder::Controller.send(:check_devices, {options: options, config: config, logger: logger})
      assert_equal RokuBuilder::GOOD_DEVICE, code

      ping.expect(:ping?, false, [parsed[:device_config][:ip], 1, 0.2, 1])
      ping.expect(:ping?, false, [raw[:devices][:a][:ip], 1, 0.2, 1])
      ping.expect(:ping?, false, [raw[:devices][:b][:ip], 1, 0.2, 1])
      code = RokuBuilder::Controller.send(:check_devices, {options: options, config: config, logger: logger})
      assert_equal RokuBuilder::NO_DEVICES, code

      ping.expect(:ping?, false, [parsed[:device_config][:ip], 1, 0.2, 1])
      ping.expect(:ping?, true, [raw[:devices][:a][:ip], 1, 0.2, 1])
      code = RokuBuilder::Controller.send(:check_devices, {options: options, config: config, logger: logger})
      assert_equal RokuBuilder::CHANGED_DEVICE, code
      assert_equal raw[:devices][:a][:ip], config.parsed[:device_config][:ip]

      options[:device_given] = true
      ping.expect(:ping?, false, [parsed[:device_config][:ip], 1, 0.2, 1])
      code = RokuBuilder::Controller.send(:check_devices, {options: options, config: config, logger: logger})
      assert_equal RokuBuilder::BAD_DEVICE, code

      options = {build: true, device_given: false}
      code = RokuBuilder::Controller.send(:check_devices, {options: options, config: config, logger: logger})
      assert_equal RokuBuilder::GOOD_DEVICE, code
    end
  end

  def bad_test_controller_run_debug
    tests = [
      {options: {debug: true}, method: :set_debug},
      {options: {verbose: true}, method: :set_info},
      {options: {}, method: :set_warn}
    ]
    tests.each do |test|
      logger = Minitest::Mock.new
      logger.expect(:call, nil)

      RokuBuilder::Logger.stub(test[:method], logger) do
        RokuBuilder::Controller.initialize_logger(options: test[:options])
      end

      logger.verify
    end
  end
end

