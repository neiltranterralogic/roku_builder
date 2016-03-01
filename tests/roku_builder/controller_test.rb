require_relative "test_helper.rb"

class ControllerTest < Minitest::Test
  def test_controller_validate_options
    logger = Logger.new("/dev/null")
    options = {
      sideload: true,
      package: true
    }
    assert_equal 1, RokuBuilder::Controller.validate_options(options: options, logger: logger)
    options = {}
    assert_equal 2,  RokuBuilder::Controller.validate_options(options: options, logger: logger)
    options = {
      sideload: true,
      working: true,
      current: true
    }
    assert_equal 3, RokuBuilder::Controller.validate_options(options: options, logger: logger)
    options = {
      sideload: true,
      working: true
    }
    assert_equal 0, RokuBuilder::Controller.validate_options(options: options, logger: logger)
    options = {
      package: true
    }
    assert_equal 4, RokuBuilder::Controller.validate_options(options: options, logger: logger)
    options = {
      package: true,
      current: true
    }
    assert_equal 5, RokuBuilder::Controller.validate_options(options: options, logger: logger)
    options = {
      deeplink: true
    }
    assert_equal 6, RokuBuilder::Controller.validate_options(options: options, logger: logger)
    options = {
      deeplink: true,
      deeplink_options: ""
    }
    assert_equal 6, RokuBuilder::Controller.validate_options(options: options, logger: logger)
  end
  def test_controller_configure
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exists?(target_config)
    assert !File.exists?(target_config)

    options = {
      configure: true,
      config: target_config,
    }

    RokuBuilder::Controller.handle_options(options: options, logger: logger)

    assert File.exists?(target_config)

    options = {
      configure: true,
      config: target_config,
      edit_params: "ip:111.222.333.444"
    }

    RokuBuilder::Controller.handle_options(options: options, logger: logger)

    assert File.exists?(target_config)
    config = RokuBuilder::ConfigManager.get_config(config: target_config, logger: logger)
    assert_equal "111.222.333.444", config[:devices][:roku][:ip]
    File.delete(target_config) if File.exists?(target_config)
  end

  def test_controller_validate
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exists?(target_config)

    # Test Missing Config
    options = {validate: true, config: target_config}
    code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
    assert_equal RokuBuilder::Controller::MISSING_CONFIG, code

    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)

    # Test Invalid config json
    options = {validate: true, config: target_config}
    RokuBuilder::ConfigManager.stub(:get_config, nil) do
      code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
    end
    assert_equal RokuBuilder::Controller::INVALID_CONFIG, code

    # Test Invalid config
    options = {validate: true, config: target_config}
    RokuBuilder::ConfigManager.stub(:validate_config, [1]) do
      code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
    end
    assert_equal RokuBuilder::Controller::INVALID_CONFIG, code

    # Test Depricated Config
    options = {validate: true, stage: 'production', config: target_config}
    RokuBuilder::ConfigManager.stub(:validate_config, [-1]) do
      code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
    end
    assert_equal RokuBuilder::Controller::DEPRICATED_CONFIG, code

    # Test valid Config
    options = {validate: true, stage: 'production', config: target_config}
    RokuBuilder::ConfigManager.stub(:validate_config, [0]) do
      RokuBuilder::Controller.stub(:check_devices, [0, nil]) do
        code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
      end
    end
    assert_equal RokuBuilder::Controller::SUCCESS, code

    # Test valid config in pwd
    options = {validate: true, stage: 'production', config: target_config}
    RokuBuilder::ConfigManager.stub(:validate_config, [0]) do
      RokuBuilder::Controller.stub(:system, "/dev/null/test") do
        RokuBuilder::Controller.stub(:check_devices, [0, nil]) do
          code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
        end
      end
    end
    assert_equal RokuBuilder::Controller::SUCCESS, code

    File.delete(target_config) if File.exists?(target_config)
  end

  def test_controller_sideload
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exists?(target_config)
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
    assert_equal RokuBuilder::Controller::SUCCESS, code

    # Test Failure
    loader.expect(:sideload, false, [sideload_config])
    RokuBuilder::Loader.stub(:new, loader) do
      RokuBuilder::Controller.stub(:check_devices, [0, {device_config: {}, sideload_config: sideload_config}]) do
        code = RokuBuilder::Controller.handle_options(options: options, logger: logger)
      end
    end
    assert_equal RokuBuilder::Controller::FAILED_SIDELOAD, code

    loader.verify
    File.delete(target_config) if File.exists?(target_config)
  end

  def test_controller_package
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exists?(target_config)
    FileUtils.cp(File.join(File.dirname(target_config), "valid_config.json"), target_config)
    loader = Minitest::Mock.new
    #TODO
  end

  def test_controller_build
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exists?(target_config)
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
    assert_equal RokuBuilder::Controller::SUCCESS, code
  end
  def test_controller_update
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exists?(target_config)
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
    assert_equal RokuBuilder::Controller::SUCCESS, code
  end

  def test_controller_deeplink
    logger = Logger.new("/dev/null")
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exists?(target_config)
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
    assert_equal RokuBuilder::Controller::SUCCESS, code
  end
end

