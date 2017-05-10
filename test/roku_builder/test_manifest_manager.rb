# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"
module RokuBuilder
  class ManifestManagerTest < Minitest::Test
    def test_manifest_manager_update
      root_dir = File.join(File.dirname(__FILE__), "test_files", "manifest_manager_test")
      FileUtils.cp(File.join(root_dir, "manifest_template"), File.join(root_dir, "manifest"))
      build_version = nil
      Time.stub(:now, Time.new(2001, 02, 01)) do
        build_version = ManifestManager.update_build(root_dir: root_dir)
      end
      assert_equal "020101.2", build_version
      FileUtils.rm(File.join(root_dir, "manifest"))
    end

    def test_manifest_manager_update_single_part_build_number
      root_dir = File.join(File.dirname(__FILE__), "test_files", "manifest_manager_test")
      FileUtils.cp(File.join(root_dir, "manifest_template_2"), File.join(root_dir, "manifest"))
      build_version = ManifestManager.update_build(root_dir: root_dir)
      assert_equal "2", build_version
      FileUtils.rm(File.join(root_dir, "manifest"))
    end

    def test_manifest_manager_build_version_zip
      root_dir = File.join(File.dirname(__FILE__), "test_files", "manifest_manager_test", "test.zip")
      build_version = nil
      build_version = ManifestManager.build_version(root_dir: root_dir)
      assert_equal "010101.1", build_version
    end

    def test_manifest_manager_update_manifest
      root_dir = File.join(File.dirname(__FILE__), "test_files", "manifest_manager_test")
      FileUtils.cp(File.join(root_dir, "manifest_template"), File.join(root_dir, "manifest"))
      attrs = {
        title: "New Title",
        major_version: 2,
        minor_version: 2,
        build_version: "020202.0002",
        mm_icon_focus_hd: "pkg:/images/focus1.png",
        mm_icon_focus_sd: "pkg:/images/focus2.png"
      }
      ManifestManager.update_manifest(root_dir: root_dir, attributes: attrs)
      assert FileUtils.compare_file(File.join(root_dir, "manifest"), File.join(root_dir, "updated_title_manifest"))
      FileUtils.rm(File.join(root_dir, "manifest"))
    end
    def test_manifest_manager_update_manifest_overwrite
      root_dir = File.join(File.dirname(__FILE__), "test_files", "manifest_manager_test")
      attrs = {
        title: "New Title",
        major_version: 2,
        minor_version: 2,
        build_version: "020202.0002",
        mm_icon_focus_hd: "pkg:/images/focus1.png",
        mm_icon_focus_sd: "pkg:/images/focus2.png"
      }
      ManifestManager.update_manifest(root_dir: root_dir, attributes: attrs)
      ManifestManager.update_manifest(root_dir: root_dir, attributes: attrs)
      assert FileUtils.compare_file(File.join(root_dir, "manifest"), File.join(root_dir, "updated_title_manifest"))
      FileUtils.rm(File.join(root_dir, "manifest"))
    end
    def test_manifest_manager_update_manifest_partial
      root_dir = File.join(File.dirname(__FILE__), "test_files", "manifest_manager_test")
      attrs = {
        title: "New Title",
        major_version: 2,
        minor_version: 2,
        build_version: "020202.0002",
        mm_icon_focus_hd: "pkg:/images/focus1.png",
        mm_icon_focus_sd: "pkg:/images/focus2.png"
      }
      ManifestManager.update_manifest(root_dir: root_dir, attributes: attrs)
      attrs = {
        title: "New Title",
      }
      ManifestManager.update_manifest(root_dir: root_dir, attributes: attrs)
      assert FileUtils.compare_file(File.join(root_dir, "manifest"), File.join(root_dir, "updated_title_manifest"))
      FileUtils.rm(File.join(root_dir, "manifest"))
    end
    def test_manifest_manager_comment_empty
      root_dir = File.join(File.dirname(__FILE__), "test_files", "manifest_manager_test")
      FileUtils.cp(File.join(root_dir, "manifest_comments"), File.join(root_dir, "manifest"))
      result = {}
      result["#comment".to_sym] = nil
      result[:title] = "title"
      result[:other] = ""
      result[:other2] = "val#comment"
      result[:other3] = "#comment"
      manifest = ManifestManager.read_manifest(root_dir: root_dir)
      assert_equal result, manifest
      FileUtils.rm(File.join(root_dir, "manifest"))
    end
  end
end
