require_relative "test_helper.rb"

class ConfigValidatorTest < Minitest::Test

  def test_config_manager_validate_devices
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices] = nil
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [1], codes
  end

  def test_config_manager_validate_devices_default
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:default] = nil
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [2], codes
  end

  def test_config_manager_validate_devices_default_is_symbol
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:default] = "bad"
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [3], codes
  end

  def test_config_manager_validate_device_ip
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:ip] = nil
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [7], codes
  end

  def test_config_manager_validate_device_ip_empty
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:ip] = ""
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [7], codes
  end

  def test_config_manager_validate_device_ip_default_value
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:ip] = "xxx.xxx.xxx.xxx"
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [7], codes
  end

  def test_config_manager_validate_device_user
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:user] = nil
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [8], codes
  end

  def test_config_manager_validate_device_user_empty
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:user] = ""
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [8], codes
  end

  def test_config_manager_validate_device_user_default_value
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:user] = "<username>"
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [8], codes
  end

  def test_config_manager_validate_device_password
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:password] = nil
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [9], codes
  end

  def test_config_manager_validate_device_password_empty
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:password] = ""
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [9], codes
  end

  def test_config_manager_validate_device_password_default_value
    logger = Logger.new("/dev/null")
    config = good_config
    config[:devices][:roku][:password] = "<password>"
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [9], codes
  end

  def test_config_manager_validate_projects
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects] = nil
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [4], codes
  end

  def test_config_manager_validate_projects_default
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:default] = nil
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [5], codes
  end

  def test_config_manager_validate_projects_default_default_value
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:default] = "<project id>".to_sym
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [5], codes
  end

  def test_config_manager_validate_projects_default_is_symbol
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:default] = "project_id"
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [6], codes
  end

  def test_config_manager_validate_project_app_name
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:project1][:app_name] = nil
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [10], codes
  end

  def test_config_manager_validate_project_directory
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:project1][:directory] = nil
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [11], codes
  end

  def test_config_manager_validate_project_folders
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:project1][:folders] = nil
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [12], codes
  end

  def test_config_manager_validate_project_folders_is_array
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:project1][:folders] = "Folders"
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [13], codes
  end

  def test_config_manager_validate_project_files
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:project1][:files] = nil
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [14], codes
  end

  def test_config_manager_validate_project_filess_is_array
    logger = Logger.new("/dev/null")
    config = good_config
    config[:projects][:project1][:files] = "Files"
    codes = RokuBuilder::ConfigValidator.validate_config(config: config, logger: logger)
    assert_equal [15], codes
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
