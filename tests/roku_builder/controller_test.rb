require "roku_builder"
require "minitest/autorun"

class ControllerTest < Minitest::Test
  def test_controller_validate_options
    options = {
      sideload: true,
      package: true
    }
    assert_equal 1, RokuBuilder::Controller.validate_options(options: options)
    options = {}
    assert_equal 2,  RokuBuilder::Controller.validate_options(options: options)
    options = {
      sideload: true,
      working: true,
      current: true
    }
    assert_equal 3, RokuBuilder::Controller.validate_options(options: options)
    options = {
      sideload: true,
      working: true
    }
    assert_equal 0, RokuBuilder::Controller.validate_options(options: options)
    options = {
      package: true
    }
    assert_equal 4, RokuBuilder::Controller.validate_options(options: options)
    options = {
      package: true,
      current: true
    }
    assert_equal 5, RokuBuilder::Controller.validate_options(options: options)
    options = {
      deeplink: true
    }
    assert_equal 6, RokuBuilder::Controller.validate_options(options: options)
    options = {
      deeplink: true,
      deeplink_options: ""
    }
    assert_equal 6, RokuBuilder::Controller.validate_options(options: options)
  end
  def test_controller_configure
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "configure_test.json")
    File.delete(target_config) if File.exists?(target_config)
    assert !File.exists?(target_config)

    options = {
      configure: true,
      config: target_config,
    }

    RokuBuilder::Controller.send(:handle_options, {options: options})

    assert File.exists?(target_config)

    options = {
      configure: true,
      config: target_config,
      edit_params: "ip:111.222.333.444"
    }

    RokuBuilder::Controller.send(:handle_options, {options: options})

    assert File.exists?(target_config)
    config = RokuBuilder::ConfigManager.get_config(config: target_config)
    assert_equal "111.222.333.444", config[:devices][:roku][:ip]
    File.delete(target_config) if File.exists?(target_config)
  end
  def test_controller_load_config
    target_config = File.join(File.dirname(__FILE__), "test_files", "controller_test", "load_config_test.json")
    #TODO
  end
end

