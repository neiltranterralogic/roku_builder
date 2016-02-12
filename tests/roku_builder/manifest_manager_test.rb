require "roku_builder"
require "minitest/autorun"

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
end
