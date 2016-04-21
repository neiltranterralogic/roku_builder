require_relative "test_helper.rb"

class ConfigParserTest < Minitest::Test
  def test_manifest_config
    logger = Logger.new("/dev/null")
    options = {
      config: File.expand_path(File.join(File.dirname(__FILE__), "test_files", "controller_config_test", "valid_config.json")),
      stage: 'production',
      update_manifest: false,
      fetch: false,
    }
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)

    assert_equal RokuBuilder::SUCCESS, code
    assert_equal Hash, config.class
    assert_equal "/dev/null", configs[:manifest_config][:root_dir]
  end

  def test_manifest_config_project_select
    logger = Logger.new("/dev/null")
    options = {
      config: File.expand_path(File.join(File.dirname(__FILE__), "test_files", "controller_config_test", "valid_config.json")),
      stage: 'production',
      update_manifest: false,
      fetch: false,
    }
    config = good_config

    code = nil
    configs = nil

    Pathname.stub(:pwd, Pathname.new("/dev/nuller")) do
      code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    end

    assert_equal RokuBuilder::SUCCESS, code
    assert_equal Hash, config.class
    assert_equal "/dev/nuller", configs[:project_config][:directory]
  end
end
