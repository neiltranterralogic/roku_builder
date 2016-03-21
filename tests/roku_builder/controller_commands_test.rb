require_relative "test_helper.rb"

class ControllerCommandsTest < Minitest::Test

  def test_controller_commands_sideload
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

  def test_controller_commands_package
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

  def test_controller_commands_package_outfile
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

  def test_controller_commands_build
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
  def test_controller_commands_update
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

  def test_controller_commands_deeplink
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
  def test_controller_commands_delete
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
  def test_controller_commands_monitor
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
  def test_controller_commands_navigate
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
  def test_controller_commands_navigate_fail
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
  def test_controller_commands_screen
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
  def test_controller_commands_screens
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
  def test_controller_commands_text
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
  def test_controller_commands_test
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
  def test_controller_commands_screencapture
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
  def test_controller_commands_screencapture_fail
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
end
