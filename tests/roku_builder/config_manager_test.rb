require "roku_builder"
require "minitest/autorun"

class ConfigManagerTest < Minitest::Test

  def test_config_manager_read_config
    logger = Logger.new("/dev/null")
    config_path = "config/file/path"
    io = Minitest::Mock.new
    io.expect(:read, good_config.to_json)
    config = nil
    File.stub(:open, io) do
      config = RokuBuilder::ConfigManager.get_config(config: config_path, logger: logger)
    end
    io.verify
    assert_equal :roku,  config[:devices][:default], :roku
    assert_equal :project1, config[:projects][:default], :project1
  end

  def test_config_manager_validate_devices
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices] = nil
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [1], codes
  end

  def test_config_manager_validate_devices_default
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:default] = nil
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [2], codes
  end

  def test_config_manager_validate_devices_default_is_symbol
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:default] = "bad"
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [3], codes
  end

  def test_config_manager_validate_device_ip
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:ip] = nil
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [7], codes
  end

  def test_config_manager_validate_device_ip_empty
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:ip] = ""
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [7], codes
  end

  def test_config_manager_validate_device_ip_default_value
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:ip] = "xxx.xxx.xxx.xxx"
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [7], codes
  end

  def test_config_manager_validate_device_user
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:user] = nil
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [8], codes
  end

  def test_config_manager_validate_device_user_empty
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:user] = ""
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [8], codes
  end

  def test_config_manager_validate_device_user_default_value
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:user] = "<username>"
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [8], codes
  end

  def test_config_manager_validate_device_password
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:password] = nil
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [9], codes
  end

  def test_config_manager_validate_device_password_empty
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:password] = ""
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [9], codes
  end

  def test_config_manager_validate_device_password_default_value
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:password] = "<password>"
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [9], codes
  end

  def test_config_manager_validate_projects
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects] = nil
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [4], codes
  end

  def test_config_manager_validate_projects_default
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:default] = nil
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [5], codes
  end

  def test_config_manager_validate_projects_default_default_value
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:default] = "<project id>".to_sym
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [5], codes
  end

  def test_config_manager_validate_projects_default_is_symbol
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:default] = "project_id"
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [6], codes
  end

  def test_config_manager_validate_project_app_name
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:project1][:app_name] = nil
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [10], codes
  end

  def test_config_manager_validate_project_directory
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:project1][:directory] = nil
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [11], codes
  end

  def test_config_manager_validate_project_folders
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:project1][:folders] = nil
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [12], codes
  end

  def test_config_manager_validate_project_folders_is_array
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:project1][:folders] = "Folders"
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [13], codes
  end

  def test_config_manager_validate_project_files
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:project1][:files] = nil
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [14], codes
  end

  def test_config_manager_validate_project_filess_is_array
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:project1][:files] = "Files"
    codes = RokuBuilder::ConfigManager.validate_config(config: config, logger: logger)
    assert_equal [15], codes
  end

  def test_config_manager_edit_ip
    logger = Logger.new("/dev/null")
    config_path = "config/file/path"
    args = {
      config: config_path,
      options: "ip:192.168.0.200",
      device: :roku,
      project: nil,
      stage: nil,
      logger: logger
    }
    new_config = good_config
    new_config[:devices][:roku][:ip] = "192.168.0.200"

    io = Minitest::Mock.new
    io.expect(:read, good_config.to_json)
    io.expect(:write, nil, [JSON.pretty_generate(new_config)])
    io.expect(:close, nil)
    config = nil
    File.stub(:open, io) do
      RokuBuilder::ConfigManager.edit_config(**args)
    end
    io.verify
  end

  def test_config_manager_edit_user
    logger = Logger.new("/dev/null")
    config_path = "config/file/path"
    args = {
      config: config_path,
      options: "user:new_user",
      device: "roku",
      project: nil,
      stage: nil,
      logger: logger
    }
    new_config = good_config
    new_config[:devices][:roku][:user] = "new_user"

    io = Minitest::Mock.new
    io.expect(:read, good_config.to_json)
    io.expect(:write, nil, [JSON.pretty_generate(new_config)])
    io.expect(:close, nil)
    config = nil
    File.stub(:open, io) do
      RokuBuilder::ConfigManager.edit_config(**args)
    end
    io.verify
  end

  def test_config_manager_edit_password
    logger = Logger.new("/dev/null")
    config_path = "config/file/path"
    args = {
      config: config_path,
      options: "password:new_password",
      device: nil,
      project: nil,
      stage: nil,
      logger: logger
    }
    new_config = good_config
    new_config[:devices][:roku][:password] = "new_password"

    io = Minitest::Mock.new
    io.expect(:read, good_config.to_json)
    io.expect(:write, nil, [JSON.pretty_generate(new_config)])
    io.expect(:close, nil)
    config = nil
    File.stub(:open, io) do
      RokuBuilder::ConfigManager.edit_config(**args)
    end
    io.verify
  end

  def test_config_manager_edit_app_name
    logger = Logger.new("/dev/null")
    config_path = "config/file/path"
    args = {
      config: config_path,
      options: "app_name:new name",
      device: nil,
      project: :project1,
      stage: nil,
      logger: logger
    }
    new_config = good_config
    new_config[:projects][:project1][:app_name] = "new name"

    io = Minitest::Mock.new
    io.expect(:read, good_config.to_json)
    io.expect(:write, nil, [JSON.pretty_generate(new_config)])
    io.expect(:close, nil)
    config = nil
    File.stub(:open, io) do
      RokuBuilder::ConfigManager.edit_config(**args)
    end
    io.verify
  end

  def test_config_manager_edit_directory
    logger = Logger.new("/dev/null")
    config_path = "config/file/path"
    args = {
      config: config_path,
      options: "directory:new/directory/path",
      device: nil,
      project: "project1",
      stage: nil,
      logger: logger
    }
    new_config = good_config
    new_config[:projects][:project1][:directory] = "new/directory/path"

    io = Minitest::Mock.new
    io.expect(:read, good_config.to_json)
    io.expect(:write, nil, [JSON.pretty_generate(new_config)])
    io.expect(:close, nil)
    config = nil
    File.stub(:open, io) do
      RokuBuilder::ConfigManager.edit_config(**args)
    end
    io.verify
  end

  def test_config_manager_edit_branch
    logger = Logger.new("/dev/null")
    config_path = "config/file/path"
    args = {
      config: config_path,
      options: "branch:new-branch",
      device: nil,
      project: nil,
      stage: :production,
      logger: logger
    }
    new_config = good_config
    new_config[:projects][:project1][:stages][:production][:branch] = "new-branch"

    io = Minitest::Mock.new
    io.expect(:read, good_config.to_json)
    io.expect(:write, nil, [JSON.pretty_generate(new_config)])
    io.expect(:close, nil)
    config = nil
    File.stub(:open, io) do
      RokuBuilder::ConfigManager.edit_config(**args)
    end
    io.verify
  end

  def test_config_manager_edit_default_stage
    logger = Logger.new("/dev/null")
    config_path = "config/file/path"
    args = {
      config: config_path,
      options: "branch:new-branch",
      device: nil,
      project: nil,
      stage: nil,
      logger: logger
    }
    new_config = good_config
    new_config[:projects][:project1][:stages][:production][:branch] = "new-branch"

    io = Minitest::Mock.new
    io.expect(:read, good_config.to_json)
    io.expect(:write, nil, [JSON.pretty_generate(new_config)])
    io.expect(:close, nil)
    config = nil
    File.stub(:open, io) do
      RokuBuilder::ConfigManager.edit_config(**args)
    end
    io.verify
  end

  def good_config
    {
      devices: {
        default: :roku,
        roku: {
          ip: "192.168.0.100",
          user: "user",
          password: "password"
        }
      },
      projects: {
        default: :project1,
        project1: {
          directory: "<path/to/repo>",
          folders: ["resources","source"],
          files: ["manifest"],
          app_name: "<app name>",
          stages:{
            production: {
              branch: "production",
              key: {
                keyed_pkg: "<path/to/signed/pkg>",
                password: "<password for pkg>"
              }
            }
          }
        }
      }
    }
  end
end
