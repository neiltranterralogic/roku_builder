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

    RokuBuilder::Controller.handle_options(options: options, logger: logger)

    assert File.exist?(target_config)

    options = {
      configure: true,
      config: target_config,
      edit_params: "ip:111.222.333.444"
    }

    RokuBuilder::Controller.handle_options(options: options, logger: logger)

    assert File.exist?(target_config)
    config = RokuBuilder::ConfigManager.get_config(config: target_config, logger: logger)
    assert_equal "111.222.333.444", config[:devices][:roku][:ip]

    options = {
      configure: true,
      config: target_config
    }

    code = RokuBuilder::Controller.handle_options(options: options, logger: logger)

    assert_equal RokuBuilder::CONFIG_OVERWRITE, code

    File.delete(target_config) if File.exist?(target_config)
  end

  def test_controller_validate
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)

    # Test Missing Config
    options = {validate: true, config: target_config}
    code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
    assert_equal RokuBuilder::MISSING_CONFIG, code

    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)

    # Test Invalid config json
    options = {validate: true, config: target_config}
    RokuBuilder::ConfigManager.stub(:get_config, nil) do
      code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
    end
    assert_equal RokuBuilder::INVALID_CONFIG, code

    # Test Invalid config
    options = {validate: true, config: target_config}
    RokuBuilder::ConfigManager.stub(:validate_config, [1]) do
      code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
    end
    assert_equal RokuBuilder::INVALID_CONFIG, code

    # Test Depricated Config
    options = {validate: true, stage: 'production', config: target_config}
    RokuBuilder::ConfigManager.stub(:validate_config, [-1]) do
      code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
    end
    assert_equal RokuBuilder::DEPRICATED_CONFIG, code

    # Test valid Config
    options = {validate: true, stage: 'production', config: target_config}
    RokuBuilder::ConfigManager.stub(:validate_config, [0]) do
      RokuBuilder::Controller.stub(:check_devices, [0, nil]) do
        code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
      end
    end
    assert_equal RokuBuilder::SUCCESS, code

    # Test valid config in pwd
    options = {validate: true, stage: 'production', config: target_config}
    RokuBuilder::ConfigManager.stub(:validate_config, [0]) do
      RokuBuilder::Controller.stub(:system, "/dev/null/test") do
        RokuBuilder::Controller.stub(:check_devices, [0, nil]) do
          code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
        end
      end
    end
    assert_equal RokuBuilder::SUCCESS, code

    File.delete(target_config) if File.exist?(target_config)
  end

  def test_controller_sideload
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)
    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)
    loader = Minitest::Mock.new

    code = nil
    options = {sideload: true, stage: 'production', config: target_config}
    sideload_config = {
      root_dir: "/dev/null",
      branch: "master",
      update_manifest: nil,
      fetch: nil,
      folders: ["resources", "source"],
      files: ["manifest"]
    }
    # Test Success
    loader.expect(:sideload, true, [sideload_config])
    RokuBuilder::Loader.stub(:new, loader) do
      RokuBuilder::Controller.stub(:check_devices, [0, {device_config: {}, sideload_config: sideload_config}]) do
        code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
      end
    end
    assert_equal RokuBuilder::SUCCESS, code

    # Test Failure
    loader.expect(:sideload, false, [sideload_config])
    RokuBuilder::Loader.stub(:new, loader) do
      RokuBuilder::Controller.stub(:check_devices, [0, {device_config: {}, sideload_config: sideload_config}]) do
        code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
      end
    end
    assert_equal RokuBuilder::FAILED_SIDELOAD, code

    loader.verify
    File.delete(target_config) if File.exist?(target_config)
  end

  def test_controller_package
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)
    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)
    keyer = Minitest::Mock.new
    loader = Minitest::Mock.new
    packager = Minitest::Mock.new
    inspector = Minitest::Mock.new

    options = {package: true, inspect: true, stage: 'production', out_folder: "/tmp", config: target_config}
    configs = {
      device_config: {},
      sideload_config: {},
      key: {},
      package_config: {
        app_name_version: "app - production - build_version",
        out_file: "/tmp/app_production_build_version.pkg"
      },
      project_config: {app_name: "app"},
      inspect_config: {}
    }
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
            RokuBuilder::Controller.stub(:check_devices, [0, configs]) do
              code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
            end
          end
        end
      end
    end
    assert_equal RokuBuilder::SUCCESS, code

    keyer.verify
    loader.verify
    packager.verify
    inspector.verify
    File.delete(target_config) if File.exist?(target_config)
  end

  def test_controller_package_outfile
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)
    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)
    keyer = Minitest::Mock.new
    loader = Minitest::Mock.new
    packager = Minitest::Mock.new
    inspector = Minitest::Mock.new

    options = {package: true, inspect: true, stage: 'production', out: "/tmp/out.pkg", config: target_config}
    configs = {
      device_config: {},
      sideload_config: {},
      key: {},
      package_config: {
        app_name_version: "app - production - build_version",
        out_file: "/tmp/out.pkg"
      },
      project_config: {app_name: "app"},
      inspect_config: {}
    }
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
            RokuBuilder::Controller.stub(:check_devices, [0, configs]) do
              code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
            end
          end
        end
      end
    end
    assert_equal RokuBuilder::SUCCESS, code

    keyer.verify
    loader.verify
    packager.verify
    inspector.verify
    File.delete(target_config) if File.exist?(target_config)
  end

  def test_controller_build
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)
    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)
    loader = Minitest::Mock.new

    code = nil
    options = {build: true, stage: 'production', out_folder: "/tmp", config: target_config}
    build_config = {
      root_dir: "/dev/null",
      branch: "master",
      outfile: "/tmp/app_production_1.zip",
      fetch: nil,
      folders: ["resources", "source"],
      files: ["manifest"]
    }
    loader.expect(:build, "/tmp/build", [build_config])
    RokuBuilder::Loader.stub(:new, loader) do
      RokuBuilder::ManifestManager.stub(:build_version, "1") do
        RokuBuilder::Controller.stub(:check_devices, [0, {device_config: {}, manifest_config: {}, project_config: {}, build_config: build_config}]) do
          code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
        end
      end
    end
    assert_equal RokuBuilder::SUCCESS, code
    loader.verify
    File.delete(target_config) if File.exist?(target_config)
  end
  def test_controller_update
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)
    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)
    mock = Minitest::Mock.new

    code = nil
    options = {update: true, stage: 'production', out_folder: "/tmp", config: target_config}
    manifest_config = {
     root_dir: "/dev/null"
    }
    mock.expect(:call, "1", [manifest_config])
    mock.expect(:call, "2", [manifest_config])
    RokuBuilder::ManifestManager.stub(:build_version, mock) do
      RokuBuilder::ManifestManager.stub(:update_build, mock) do
        RokuBuilder::Controller.stub(:check_devices, [0, {device_config: {}, manifest_config: manifest_config}]) do
          code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
        end
      end
    end
    mock.verify
    assert_equal RokuBuilder::SUCCESS, code
    File.delete(target_config) if File.exist?(target_config)
  end

  def test_controller_deeplink
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)
    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)
    mock = Minitest::Mock.new

    code = nil
    options = {deeplink: true, stage: 'production', deeplink_options: "a:b", config: target_config}
    deeplink_config = {
     root_dir: "/dev/null"
    }
    mock.expect(:link, "true", [deeplink_config])
    RokuBuilder::Linker.stub(:new, mock) do
      RokuBuilder::Controller.stub(:check_devices, [0, {device_config: {}, deeplink_config: deeplink_config}]) do
        code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
      end
    end
    mock.verify
    assert_equal RokuBuilder::SUCCESS, code
    File.delete(target_config) if File.exist?(target_config)
  end
  def test_controller_delete
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)
    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)
    loader = Minitest::Mock.new

    options = {delete: true, stage: 'production', config: target_config}
    loader.expect(:unload, nil)
    code = nil
    RokuBuilder::Loader.stub(:new, loader) do
      RokuBuilder::ManifestManager.stub(:build_version, "1") do
        RokuBuilder::Controller.stub(:check_devices, [0, {device_config: {}}]) do
          code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
        end
      end
    end
    assert_equal RokuBuilder::SUCCESS, code
    loader.verify
    File.delete(target_config) if File.exist?(target_config)
  end
  def test_controller_monitor
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)
    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)
    monitor = Minitest::Mock.new

    options = {monitor: "main", stage: 'production', config: target_config}
    monitor.expect(:monitor, nil, [{}])
    code = nil
    RokuBuilder::Monitor.stub(:new, monitor) do
      RokuBuilder::ManifestManager.stub(:build_version, "1") do
        RokuBuilder::Controller.stub(:check_devices, [0, {device_config: {}, monitor_config: {}}]) do
          code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
        end
      end
    end
    assert_equal RokuBuilder::SUCCESS, code
    monitor.verify
    File.delete(target_config) if File.exist?(target_config)
  end
  def test_controller_navigate
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)
    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)
    navigator = Minitest::Mock.new

    options = {navigate: "up", stage: 'production', config: target_config}
    navigator.expect(:nav, true, [{}])
    code = nil
    RokuBuilder::Navigator.stub(:new, navigator) do
      RokuBuilder::ManifestManager.stub(:build_version, "1") do
        RokuBuilder::Controller.stub(:check_devices, [0, {device_config: {}, navigate_config: {}}]) do
          code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
        end
      end
    end
    assert_equal RokuBuilder::SUCCESS, code
    navigator.verify
    File.delete(target_config) if File.exist?(target_config)
  end
  def test_controller_navigate_fail
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)
    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)
    navigator = Minitest::Mock.new

    options = {navigate: "up", stage: 'production', config: target_config}
    navigator.expect(:nav, nil, [{}])
    code = nil
    RokuBuilder::Navigator.stub(:new, navigator) do
      RokuBuilder::ManifestManager.stub(:build_version, "1") do
        RokuBuilder::Controller.stub(:check_devices, [0, {device_config: {}, navigate_config: {}}]) do
          code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
        end
      end
    end
    assert_equal RokuBuilder::FAILED_NAVIGATING, code
    navigator.verify
    File.delete(target_config) if File.exist?(target_config)
  end
  def test_controller_screen
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)
    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)
    navigator = Minitest::Mock.new

    options = {screen: "secret", stage: 'production', config: target_config}
    navigator.expect(:screen, true, [{}])
    code = nil
    RokuBuilder::Navigator.stub(:new, navigator) do
      RokuBuilder::ManifestManager.stub(:build_version, "1") do
        RokuBuilder::Controller.stub(:check_devices, [0, {device_config: {}, screen_config: {}}]) do
          code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
        end
      end
    end
    assert_equal RokuBuilder::SUCCESS, code
    navigator.verify
    File.delete(target_config) if File.exist?(target_config)
  end
  def test_controller_screens
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)
    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)
    navigator = Minitest::Mock.new

    options = {screens: true, stage: 'production', config: target_config}
    navigator.expect(:screens, true)
    code = nil
    RokuBuilder::Navigator.stub(:new, navigator) do
      RokuBuilder::ManifestManager.stub(:build_version, "1") do
        RokuBuilder::Controller.stub(:check_devices, [0, {device_config: {}}]) do
          code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
        end
      end
    end
    assert_equal RokuBuilder::SUCCESS, code
    navigator.verify
    File.delete(target_config) if File.exist?(target_config)
  end
  def test_controller_text
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)
    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)
    navigator = Minitest::Mock.new

    options = {text: "text string", stage: 'production', config: target_config}
    navigator.expect(:type, true, [{}])
    code = nil
    RokuBuilder::Navigator.stub(:new, navigator) do
      RokuBuilder::ManifestManager.stub(:build_version, "1") do
        RokuBuilder::Controller.stub(:check_devices, [0, {device_config: {}, text_config: {}}]) do
          code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
        end
      end
    end
    assert_equal RokuBuilder::SUCCESS, code
    navigator.verify
    File.delete(target_config) if File.exist?(target_config)
  end
  def test_controller_test
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)
    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)
    tester = Minitest::Mock.new

    options = {test: true, stage: 'production', config: target_config}
    tester.expect(:run_tests, true, [{}])
    code = nil
    RokuBuilder::Tester.stub(:new, tester) do
      RokuBuilder::ManifestManager.stub(:build_version, "1") do
        RokuBuilder::Controller.stub(:check_devices, [0, {device_config: {}, test_config: {}}]) do
          code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
        end
      end
    end
    assert_equal RokuBuilder::SUCCESS, code
    tester.verify
    File.delete(target_config) if File.exist?(target_config)
  end
  def test_controller_screencapture
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)
    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)
    inspector = Minitest::Mock.new

    options = {screencapture: true, stage: 'production', out: "/tmp/capture.jpg", config: target_config}
    inspector.expect(:screencapture, true, [{}])
    code = nil
    RokuBuilder::Inspector.stub(:new, inspector) do
      RokuBuilder::ManifestManager.stub(:build_version, "1") do
        RokuBuilder::Controller.stub(:check_devices, [0, {device_config: {}, screencapture_config: {}}]) do
          code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
        end
      end
    end
    assert_equal RokuBuilder::SUCCESS, code
    inspector.verify
    File.delete(target_config) if File.exist?(target_config)
  end
  def test_controller_screencapture_fail
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exist?(target_config)
    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)
    inspector = Minitest::Mock.new

    options = {screencapture: true, stage: 'production', out: "/tmp", config: target_config}
    inspector.expect(:screencapture, false, [{}])
    code = nil
    RokuBuilder::Inspector.stub(:new, inspector) do
      RokuBuilder::ManifestManager.stub(:build_version, "1") do
        RokuBuilder::Controller.stub(:check_devices, [0, {device_config: {}, screencapture_config: {}}]) do
          code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
        end
      end
    end
    assert_equal RokuBuilder::FAILED_SCREENCAPTURE, code
    inspector.verify
    File.delete(target_config) if File.exist?(target_config)
  end

  def test_controller_handel_error_codes
    error_groups = {
      fatal: {
        options_code: [
          RokuBuilder::EXTRA_COMMANDS,
          RokuBuilder::NO_COMMANDS,
          RokuBuilder::EXTRA_SOURCES,
          RokuBuilder::NO_SOURCE,
          RokuBuilder::BAD_CURRENT,
          RokuBuilder::BAD_DEEPLINK,
          RokuBuilder::BAD_IN_FILE
        ],
        device_code: [
          RokuBuilder::BAD_DEVICE,
          RokuBuilder::NO_DEVICES,
        ],
        command_code: [
          RokuBuilder::CONFIG_OVERWRITE,
          RokuBuilder::MISSING_CONFIG,
          RokuBuilder::INVALID_CONFIG,
          RokuBuilder::MISSING_MANIFEST,
          RokuBuilder::UNKNOWN_DEVICE,
          RokuBuilder::UNKNOWN_PROJECT,
          RokuBuilder::UNKNOWN_STAGE,
          RokuBuilder::FAILED_SIDELOAD,
          RokuBuilder::FAILED_SIGNING,
          RokuBuilder::FAILED_DEEPLINKING,
          RokuBuilder::FAILED_NAVIGATING,
          RokuBuilder::FAILED_SCREENCAPTURE
        ]
      },
      info: {
        device_code: [
          RokuBuilder::CHANGED_DEVICE
        ]
      },
      warn: {
        command_code: [
          RokuBuilder::DEPRICATED_CONFIG
        ]
      }
    }

    error_groups.each_pair do |type,errors|
      errors.each_pair do |key,value|
        value.each do |code|
          logger = Minitest::Mock.new
          options = {options: {}, logger: logger}
          options[key] = code
          logger.expect(type, nil)  {|string| string.class == String}
          method = "handle_#{key}s"
          RokuBuilder::Controller.send(method.to_sym, **options)
          logger.verify
        end
      end
    end
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
    logger = Minitest::Mock.new
    options = {debug: true}

    logger.expect(:formater=, nil) do |proc_object|
      proc_object.class == PROC and proc_object.arity == 4
    end
    logger.expect(:level=, nil, [Logger::DEBUG])
    RokuBuilder::Controller.stub(:validate_options, nil) do
      RokuBuilder::Controller.stub(:handle_options, nil) do
        RokuBuilder::Controller.stub(:handle_options_codes, nil) do
          RokuBuilder::Controller.stub(:handle_command_codes, nil) do
            RokuBuilder::Controller.run(options: options)
          end
        end
      end
    end
  end
  def test_controller_run_info
    logger = Minitest::Mock.new
    options = {verbose: true}

    logger.expect(:formater=, nil) do |proc_object|
      proc_object.class == PROC and proc_object.arity == 4
    end
    logger.expect(:level=, nil, [Logger::INFO])
    RokuBuilder::Controller.stub(:validate_options, nil) do
      RokuBuilder::Controller.stub(:handle_options, nil) do
        RokuBuilder::Controller.stub(:handle_options_codes, nil) do
          RokuBuilder::Controller.stub(:handle_command_codes, nil) do
            RokuBuilder::Controller.run(options: options)
          end
        end
      end
    end
  end
  def test_controller_run_warn
    logger = Minitest::Mock.new
    options = {}

    logger.expect(:formater=, nil) do |proc_object|
      proc_object.class == PROC and proc_object.arity == 4
    end
    logger.expect(:level=, nil, [Logger::WARN])
    RokuBuilder::Controller.stub(:validate_options, nil) do
      RokuBuilder::Controller.stub(:handle_options, nil) do
        RokuBuilder::Controller.stub(:handle_options_codes, nil) do
          RokuBuilder::Controller.stub(:handle_command_codes, nil) do
            RokuBuilder::Controller.run(options: options)
          end
        end
      end
    end
  end
end

