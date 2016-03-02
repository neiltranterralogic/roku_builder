require_relative "test_helper.rb"

class ManifestManagerTest < Minitest::Test
  def test_manifest_manager_update
    logger = Logger.new('/dev/null')
    root_dir = File.join(File.dirname(__FILE__), "test_files", "manifest_manager_test")
    FileUtils.cp(File.join(root_dir, "manifest_template"), File.join(root_dir, "manifest"))
    build_version = nil
    Time.stub(:now, Time.new(2001, 02, 01)) do
      build_version = RokuBuilder::ManifestManager.update_build(root_dir: root_dir, logger: logger)
    end
    assert_equal "020101.2", build_version
    FileUtils.rm(File.join(root_dir, "manifest"))
  end

  def test_manifest_manager_update_missing_build_number
    logger = Logger.new('/dev/null')
    root_dir = File.join(File.dirname(__FILE__), "test_files", "manifest_manager_test")
    FileUtils.cp(File.join(root_dir, "manifest_template_2"), File.join(root_dir, "manifest"))
    build_version = nil
    Time.stub(:now, Time.new(2001, 02, 01)) do
      build_version = RokuBuilder::ManifestManager.update_build(root_dir: root_dir, logger: logger)
    end
    assert_equal "020101.1", build_version
    FileUtils.rm(File.join(root_dir, "manifest"))
  end

  def test_manifest_manager_build_version
    logger = Logger.new('/dev/null')
    root_dir = File.join(File.dirname(__FILE__), "test_files", "manifest_manager_test")
    FileUtils.cp(File.join(root_dir, "manifest_template"), File.join(root_dir, "manifest"))
    build_version = nil
    build_version = RokuBuilder::ManifestManager.build_version(root_dir: root_dir, logger: logger)
    assert_equal "010101.1", build_version
    FileUtils.rm(File.join(root_dir, "manifest"))
  end
end
