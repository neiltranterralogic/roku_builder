# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class Scriptertest < Minitest::Test

    def test_scripter_print_bad_attr
      code = Scripter.print(attribute: :bad, configs: {})
      assert_equal BAD_PRINT_ATTRIBUTE, code
    end

    def test_scripter_print_config_root_dir
      call_count = 0
      code = nil
      fake_print = lambda { |message, path|
        assert_equal "%s", message
        assert_equal "/dev/null", path
        call_count+=1
      }
      configs = {project_config: {directory: "/dev/null"}}
      Scripter.stub(:printf, fake_print) do
        code = Scripter.print(attribute: :root_dir, configs: configs)
      end
      assert_equal 1, call_count
      assert_equal SUCCESS, code
    end
    def test_scripter_print_config_app_name
      call_count = 0
      code = nil
      fake_print = lambda { |message, path|
        assert_equal "%s", message
        assert_equal "TestApp", path
        call_count+=1
      }
      configs = {project_config: {app_name: "TestApp"}}
      Scripter.stub(:printf, fake_print) do
        code = Scripter.print(attribute: :app_name, configs: configs)
      end
      assert_equal 1, call_count
      assert_equal SUCCESS, code
    end

    def test_scripter_print_manifest_title
      call_count = 0
      code = nil
      fake_print = lambda { |message, title|
        assert_equal "%s", message
        assert_equal "title", title
        call_count+=1
      }
      manifest = {title: "title"}
      configs = {project_config: {directory: "/dev/null"}}
      Scripter.stub(:printf, fake_print) do
        ManifestManager.stub(:read_manifest, manifest) do
          code = Scripter.print(attribute: :title, configs: configs)
        end
      end
      assert_equal 1, call_count
      assert_equal SUCCESS, code
    end

    def test_scripter_print_manifest_build_version
      call_count = 0
      code = nil
      fake_print = lambda { |message, build|
        assert_equal "%s", message
        assert_equal "010101.0001", build
        call_count+=1
      }
      manifest = {build_version: "010101.0001"}
      configs = {project_config: {directory: "/dev/null"}}
      Scripter.stub(:printf, fake_print) do
        ManifestManager.stub(:read_manifest, manifest) do
          code = Scripter.print(attribute: :build_version, configs: configs)
        end
      end
      assert_equal 1, call_count
      assert_equal SUCCESS, code
    end

    def test_scripter_print_manifest_app_version
      call_count = 0
      code = nil
      fake_print = lambda { |message, major, minor|
        assert_equal "%s.%s", message
        assert_equal "1", major
        assert_equal "0", minor
        call_count+=1
      }
      manifest = {major_version: "1", minor_version: "0"}
      configs = {project_config: {directory: "/dev/null"}}
      Scripter.stub(:printf, fake_print) do
        ManifestManager.stub(:read_manifest, manifest) do
          code = Scripter.print(attribute: :app_version, configs: configs)
        end
      end
      assert_equal 1, call_count
      assert_equal SUCCESS, code
    end
  end
end
