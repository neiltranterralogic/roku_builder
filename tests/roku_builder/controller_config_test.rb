require_relative "test_helper.rb"

class ControllerConfigTest < Minitest::Test
  def test_manifest_config
    logger = Logger.new("/dev/null")
    options = {
      config: File.expand_path(File.join(File.dirname(__FILE__), "test_files", "controller_config_test", "valid_config.json")),
      stage: 'production',
      update_manifest: false,
      fetch: false,
    }
    code, config, configs = RokuBuilder::Controller.load_config(options: options, logger: logger)

    assert_equal RokuBuilder::SUCCESS, code
    assert_equal Hash, config.class
    assert_equal "/dev/null", configs[:manifest_config][:root_dir]
    assert_equal logger, configs[:manifest_config][:logger]


  end
end
