# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

class ConfigTest < Minitest::Test

  def test_config_init
    options = {config: File.join(test_files_path(ConfigTest), "config.json")}
    config = RokuBuilder::Config.new(options: options)
  end

  def test_missing_config
    options = {config: File.join(test_files_path(ConfigTest), "missing.json")}
    assert_raises ArgumentError do
      config = RokuBuilder::Config.new(options: options)
    end
  end

  def test_invalid_config
    options = {config: File.join(test_files_path(ConfigTest), "bad.json")}
    assert_raises RokuBuilder::InvalidConfig do
      config = RokuBuilder::Config.new(options: options)
    end
  end

  def test_non_json_config
    options = {config: File.join(test_files_path(ConfigTest), "non_json.json")}
    assert_raises RokuBuilder::InvalidConfig do
      config = RokuBuilder::Config.new(options: options)
    end
  end

  def test_config_parse
    options = {config: File.join(test_files_path(ConfigTest), "config.json")}
    config = RokuBuilder::Config.new(options: options)
    config.parse
    assert_equal Hash, config.parsed.class
  end

  def test_config_read
    options = {config: File.join(test_files_path(ConfigTest), "config.json")}
    config = RokuBuilder::Config.new(options: options)
    assert_equal :roku, config.raw[:devices][:default]
    assert_equal :p1, config.raw[:projects][:default]
  end

  def test_config_read_parent
    options = {config: File.join(test_files_path(ConfigTest), "child.json")}
    config = RokuBuilder::Config.new(options: options)
    assert_equal :roku, config.raw[:devices][:default]
    assert_equal :p1, config.raw[:projects][:default]
  end
end
