require_relative "test_helper.rb"

class RokuBuilder::Controller
  class << self
    def abort
      #do nothing
    end
  end
end

class ControllerTest < Minitest::Test
  def test_controller_validate_options
    logger = Logger.new("/dev/null")
    options = {
      sideload: true,
      package: true
    }
    assert_equal RokuBuilder::EXTRA_COMMANDS, RokuBuilder::Controller.validate_options(options: options, logger: logger)
    options = {}
    assert_equal RokuBuilder::NO_COMMANDS,  RokuBuilder::Controller.validate_options(options: options, logger: logger)
    options = {
      sideload: true,
      working: true,
      current: true
    }
    assert_equal RokuBuilder::EXTRA_SOURCES, RokuBuilder::Controller.validate_options(options: options, logger: logger)
    options = {
      sideload: true,
      working: true
    }
    assert_equal RokuBuilder::VALID, RokuBuilder::Controller.validate_options(options: options, logger: logger)
    options = {
      package: true
    }
    assert_equal RokuBuilder::NO_SOURCE, RokuBuilder::Controller.validate_options(options: options, logger: logger)
    options = {
      package: true,
      current: true
    }
    assert_equal RokuBuilder::BAD_CURRENT, RokuBuilder::Controller.validate_options(options: options, logger: logger)
    options = {
      deeplink: true
    }
    assert_equal RokuBuilder::BAD_DEEPLINK, RokuBuilder::Controller.validate_options(options: options, logger: logger)
    options = {
      deeplink: true,
      deeplink_options: ""
    }
    assert_equal RokuBuilder::BAD_DEEPLINK, RokuBuilder::Controller.validate_options(options: options, logger: logger)
    options = {
      sideload: true,
      in: "",
      current: true
    }
    assert_equal RokuBuilder::VALID, RokuBuilder::Controller.validate_options(options: options, logger: logger)
    options = {
      package: true,
      in: "",
      set_stage: true
    }
    assert_equal RokuBuilder::BAD_IN_FILE, RokuBuilder::Controller.validate_options(options: options, logger: logger)
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

    code = RokuBuilder::Controller.configure(options: options, logger: logger)

    assert File.exist?(target_config)

    options = {
      configure: true,
      config: target_config,
      edit_params: "ip:111.222.333.444"
    }

    code = RokuBuilder::Controller.configure(options: options, logger: logger)

    assert File.exist?(target_config)
    config = RokuBuilder::ConfigManager.get_config(config: target_config, logger: logger)
    assert_equal "111.222.333.444", config[:devices][:roku][:ip]

    options = {
      configure: true,
      config: target_config
    }

    code = RokuBuilder::Controller.configure(options: options, logger: logger)

    assert_equal RokuBuilder::CONFIG_OVERWRITE, code

    File.delete(target_config) if File.exist?(target_config)
  end


  def test_controller_sideload
    logger = Logger.new("/dev/null")
    loader = Minitest::Mock.new

    options = {sideload: true, stage: 'production', config: "~/.roku_config.rb"}
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    # Test Success
    loader.expect(:sideload, true, [configs[:sideload_config]])
    RokuBuilder::Loader.stub(:new, loader) do
      code = RokuBuilder::Controller.execute_commands(options: options, config: config, configs: configs, logger: logger)
    end
    assert_equal RokuBuilder::SUCCESS, code

    # Test Failure
    loader.expect(:sideload, false, [configs[:sideload_config]])
    RokuBuilder::Loader.stub(:new, loader) do
      code = RokuBuilder::Controller.execute_commands(options: options, config: config, configs: configs, logger: logger)
    end
    assert_equal RokuBuilder::FAILED_SIDELOAD, code

    loader.verify
  end

  def test_controller_package
    logger = Logger.new("/dev/null")
    keyer = Minitest::Mock.new
    loader = Minitest::Mock.new
    packager = Minitest::Mock.new
    inspector = Minitest::Mock.new

    options = {package: true, inspect: true, stage: 'production', out_folder: "/tmp", config: "~/.roku_config.json"}
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    info = {app_name: "app", dev_id: "id", creation_date: "date", dev_zip: ""}

    loader.expect(:sideload, "build_version", [configs[:sideload_config]])
    keyer.expect(:rekey, true, [configs[:key]])
    packager.expect(:package, true, [configs[:package_config]])
    inspector.expect(:inspect, info, [configs[:inspect_config]])

    code = nil
    RokuBuilder::Keyer.stub(:new, keyer) do
      RokuBuilder::Loader.stub(:new, loader) do
        RokuBuilder::Packager.stub(:new, packager) do
          RokuBuilder::Inspector.stub(:new, inspector) do
            code = RokuBuilder::Controller.execute_commands(options: options, config: config, configs: configs, logger: logger)
          end
        end
      end
    end
    assert_equal RokuBuilder::SUCCESS, code

    keyer.verify
    loader.verify
    packager.verify
    inspector.verify
  end

  def test_controller_package_outfile
    logger = Logger.new("/dev/null")
    keyer = Minitest::Mock.new
    loader = Minitest::Mock.new
    packager = Minitest::Mock.new
    inspector = Minitest::Mock.new

    options = {package: true, inspect: true, stage: 'production', out: "/tmp/out.pkg", config: "~/.roku_config.json"}
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    info = {app_name: "app", dev_id: "id", creation_date: "date", dev_zip: ""}

    loader.expect(:sideload, "build_version", [configs[:sideload_config]])
    keyer.expect(:rekey, true, [configs[:key]])
    packager.expect(:package, true, [configs[:package_config]])
    inspector.expect(:inspect, info, [configs[:inspect_config]])

    code = nil
    RokuBuilder::Keyer.stub(:new, keyer) do
      RokuBuilder::Loader.stub(:new, loader) do
        RokuBuilder::Packager.stub(:new, packager) do
          RokuBuilder::Inspector.stub(:new, inspector) do
            code = RokuBuilder::Controller.execute_commands(options: options, config: config, configs: configs, logger: logger)
          end
        end
      end
    end
    assert_equal RokuBuilder::SUCCESS, code

    keyer.verify
    loader.verify
    packager.verify
    inspector.verify
  end

  def test_controller_build
    logger = Logger.new("/dev/null")
    loader = Minitest::Mock.new

    code = nil
    options = {build: true, stage: 'production', out_folder: "/tmp", config: "~/.roku_config.json"}
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    loader.expect(:build, "/tmp/build", [configs[:build_config]])
    RokuBuilder::Loader.stub(:new, loader) do
      RokuBuilder::ManifestManager.stub(:build_version, "1") do
        code = RokuBuilder::Controller.execute_commands(options: options, config: config, configs: configs, logger: logger)
      end
    end
    assert_equal RokuBuilder::SUCCESS, code
    loader.verify
  end
  def test_controller_update
    logger = Logger.new("/dev/null")
    mock = Minitest::Mock.new

    code = nil
    options = {update: true, stage: 'production', out_folder: "/tmp", config: ":execute_commands,/.roku_config.json"}
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    mock.expect(:call, "1", [configs[:manifest_config]])
    mock.expect(:call, "2", [configs[:manifest_config]])
    RokuBuilder::ManifestManager.stub(:build_version, mock) do
      RokuBuilder::ManifestManager.stub(:update_build, mock) do
        code = RokuBuilder::Controller.execute_commands(options: options, config: config, configs: configs, logger: logger)
      end
    end
    mock.verify
    assert_equal RokuBuilder::SUCCESS, code
  end

  def test_controller_deeplink
    logger = Logger.new("/dev/null")
    mock = Minitest::Mock.new

    code = nil
    options = {deeplink: true, stage: 'production', deeplink_options: "a:b", config: ":execute_commands,/.roku_config.json"}
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    mock.expect(:link, "true", [configs[:deeplink_config]])
    RokuBuilder::Linker.stub(:new, mock) do
      code = RokuBuilder::Controller.execute_commands(options: options, config: config, configs: configs, logger: logger)
    end
    mock.verify
    assert_equal RokuBuilder::SUCCESS, code
  end
  def test_controller_delete
    logger = Logger.new("/dev/null")
    loader = Minitest::Mock.new

    options = {delete: true, stage: 'production', config: ":execute_commands,/.roku_config.json"}
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    loader.expect(:unload, nil)
    code = nil
    RokuBuilder::Loader.stub(:new, loader) do
      RokuBuilder::ManifestManager.stub(:build_version, "1") do
        code = RokuBuilder::Controller.execute_commands(options: options, config: config, configs: configs, logger: logger)
      end
    end
    assert_equal RokuBuilder::SUCCESS, code
    loader.verify
  end
  def test_controller_monitor
    logger = Logger.new("/dev/null")
    monitor = Minitest::Mock.new

    options = {monitor: "main", stage: 'production', config: ":execute_commands,/.roku_config.json"}
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    monitor.expect(:monitor, nil, [configs[:monitor_config]])
    code = nil
    RokuBuilder::Monitor.stub(:new, monitor) do
      RokuBuilder::ManifestManager.stub(:build_version, "1") do
        code = RokuBuilder::Controller.execute_commands(options: options, config: config, configs: configs, logger: logger)
      end
    end
    assert_equal RokuBuilder::SUCCESS, code
    monitor.verify
  end
  def test_controller_navigate
    logger = Logger.new("/dev/null")
    navigator = Minitest::Mock.new

    options = {navigate: "up", stage: 'production', config: ":execute_commands,/.roku_config.json"}
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    navigator.expect(:nav, true, [configs[:navigate_config]])
    code = nil
    RokuBuilder::Navigator.stub(:new, navigator) do
      code = RokuBuilder::Controller.execute_commands(options: options, config: config, configs: configs, logger: logger)
    end
    assert_equal RokuBuilder::SUCCESS, code
    navigator.verify
  end
  def test_controller_navigate_fail
    logger = Logger.new("/dev/null")
    navigator = Minitest::Mock.new

    options = {navigate: "up", stage: 'production', config: ":execute_commands,/.roku_config.json"}
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    navigator.expect(:nav, nil, [configs[:navigate_config]])
    code = nil
    RokuBuilder::Navigator.stub(:new, navigator) do
      code = RokuBuilder::Controller.execute_commands(options: options, config: config, configs: configs, logger: logger)
    end
    assert_equal RokuBuilder::FAILED_NAVIGATING, code
    navigator.verify
  end
  def test_controller_screen
    logger = Logger.new("/dev/null")
    navigator = Minitest::Mock.new

    options = {screen: "secret", stage: 'production', config: ":execute_commands,/.roku_config.json"}
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    navigator.expect(:screen, true, [configs[:screen_config]])
    code = nil
    RokuBuilder::Navigator.stub(:new, navigator) do
      code = RokuBuilder::Controller.execute_commands(options: options, config: config, configs: configs, logger: logger)
    end
    assert_equal RokuBuilder::SUCCESS, code
    navigator.verify
  end
  def test_controller_screens
    logger = Logger.new("/dev/null")
    navigator = Minitest::Mock.new

    options = {screens: true, stage: 'production', config: ":execute_commands,/.roku_config.json"}
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    navigator.expect(:screens, true)
    code = nil
    RokuBuilder::Navigator.stub(:new, navigator) do
      code = RokuBuilder::Controller.execute_commands(options: options, config: config, configs: configs, logger: logger)
    end
    assert_equal RokuBuilder::SUCCESS, code
    navigator.verify
  end
  def test_controller_text
    logger = Logger.new("/dev/null")
    navigator = Minitest::Mock.new

    options = {text: "text string", stage: 'production', config: ":execute_commands,/.roku_config.json"}
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    navigator.expect(:type, true, [configs[:text_config]])
    code = nil
    RokuBuilder::Navigator.stub(:new, navigator) do
      code = RokuBuilder::Controller.execute_commands(options: options, config: config, configs: configs, logger: logger)
    end
    assert_equal RokuBuilder::SUCCESS, code
    navigator.verify
  end
  def test_controller_test
    logger = Logger.new("/dev/null")
    tester = Minitest::Mock.new

    options = {test: true, stage: 'production', config: ":execute_commands,/.roku_config.json"}
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    tester.expect(:run_tests, true, [configs[:test_config]])
    code = nil
    RokuBuilder::Tester.stub(:new, tester) do
      code = RokuBuilder::Controller.execute_commands(options: options, config: config, configs: configs, logger: logger)
    end
    assert_equal RokuBuilder::SUCCESS, code
    tester.verify
  end
  def test_controller_screencapture
    logger = Logger.new("/dev/null")
    inspector = Minitest::Mock.new

    options = {screencapture: true, stage: 'production', out: "/tmp/capture.jpg", config: ":execute_commands,/.roku_config.json"}
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    inspector.expect(:screencapture, true, [configs[:screencapture_config]])
    code = nil
    RokuBuilder::Inspector.stub(:new, inspector) do
      code = RokuBuilder::Controller.execute_commands(options: options, config: config, configs: configs, logger: logger)
    end
    assert_equal RokuBuilder::SUCCESS, code
    inspector.verify
  end
  def test_controller_screencapture_fail
    logger = Logger.new("/dev/null")
    inspector = Minitest::Mock.new

    options = {screencapture: true, stage: 'production', out: "/tmp", config: ":execute_commands,/.roku_config.json"}
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    inspector.expect(:screencapture, false, [configs[:screencapture_config]])
    code = nil
    RokuBuilder::Inspector.stub(:new, inspector) do
      code = RokuBuilder::Controller.execute_commands(options: options, config: config, configs: configs, logger: logger)
    end
    assert_equal RokuBuilder::FAILED_SCREENCAPTURE, code
    inspector.verify
  end

  def test_controller_check_devices
    logger = Logger.new("/dev/null")
    ping = Minitest::Mock.new
    options = {device_given: false}
    config = {}
    config[:devices] = {
      a: {ip: "2.2.2.2"},
      b: {ip: "3.3.3.3"}
    }
    configs = {
      device_config: {ip: "1.1.1.1"}
    }

    Net::Ping::External.stub(:new, ping) do

      ping.expect(:ping?, true, [configs[:device_config][:ip], 1, 0.2, 1])
      code, ret = RokuBuilder::Controller.check_devices(options: options, config: config, configs: configs, logger: logger)
      assert_equal RokuBuilder::GOOD_DEVICE, code

      ping.expect(:ping?, false, [configs[:device_config][:ip], 1, 0.2, 1])
      ping.expect(:ping?, false, [config[:devices][:a][:ip], 1, 0.2, 1])
      ping.expect(:ping?, false, [config[:devices][:b][:ip], 1, 0.2, 1])
      code, ret = RokuBuilder::Controller.check_devices(options: options, config: config, configs: configs, logger: logger)
      assert_equal RokuBuilder::NO_DEVICES, code

      ping.expect(:ping?, false, [configs[:device_config][:ip], 1, 0.2, 1])
      ping.expect(:ping?, true, [config[:devices][:a][:ip], 1, 0.2, 1])
      code, ret = RokuBuilder::Controller.check_devices(options: options, config: config, configs: configs, logger: logger)
      assert_equal RokuBuilder::CHANGED_DEVICE, code
      assert_equal config[:devices][:a][:ip], ret[:device_config][:ip]

      options[:device_given] = true
      ping.expect(:ping?, false, [configs[:device_config][:ip], 1, 0.2, 1])
      code, ret = RokuBuilder::Controller.check_devices(options: options, config: config, configs: configs, logger: logger)
      assert_equal RokuBuilder::BAD_DEVICE, code
    end
  end

  def test_controller_run_debug
    tests = [
      {options: {debug: true}, level: Logger::DEBUG},
      {options: {verbose: true}, level: Logger::INFO},
      {options: {}, level: Logger::WARN}
    ]
    tests.each do |test|
      logger = Minitest::Mock.new
      logger.expect(:formatter=, nil) do |proc_object|
        proc_object.class == Proc and proc_object.arity == 4
      end
      logger.expect(:level=, nil, [test[:level]])
      Logger.stub(:new, logger) do
        RokuBuilder::Controller.stub(:validate_options, nil) do
          RokuBuilder::ErrorHandler.stub(:handle_options_codes, nil) do
            RokuBuilder::Controller.stub(:configure, nil) do
              RokuBuilder::ErrorHandler.stub(:handle_configure_codes, nil) do
                RokuBuilder::ConfigManager.stub(:load_config, nil) do
                  RokuBuilder::ErrorHandler.stub(:handle_load_codes, nil) do
                    RokuBuilder::Controller.stub(:check_devices, nil) do
                      RokuBuilder::ErrorHandler.stub(:handle_device_codes, nil) do
                        RokuBuilder::Controller.stub(:execute_commands, nil) do
                          RokuBuilder::ErrorHandler.stub(:handle_command_codes, nil) do
                            RokuBuilder::Controller.run(options: test[:options])
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
      logger.verify
    end
  end
end

