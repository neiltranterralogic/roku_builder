require_relative "test_helper.rb"

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

  def test_config_manager_read_invalid_config
    logger = Logger.new("/dev/null")
    config_path = "config/file/path"
    io = Minitest::Mock.new
    io.expect(:read, good_config.to_json+"}}}}}")
    config = nil
    File.stub(:open, io) do
      config = RokuBuilder::ConfigManager.get_config(config: config_path, logger: logger)
    end
    io.verify
    assert_nil config
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
