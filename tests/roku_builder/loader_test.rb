require "roku_builder"
require "minitest/autorun"

class LoaderTest < Minitest::Test
  def test_loader_sideload
    connection = Minitest::Mock.new
    faraday = Minitest::Mock.new
    io = Minitest::Mock.new
    response = Minitest::Mock.new

    root_dir = File.join(File.dirname(__FILE__), "test_files", "loader_test")
    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password"
    }
    loader_config = {
      root_dir: root_dir,
      folders: ["source"],
      files: ["manifest"]
    }
    payload = {
      mysubmit: "Replace",
      archive: io,
    }
    path = "/plugin_install"

    faraday.expect(:request, nil, [:digest, device_config[:user], device_config[:password]])
    faraday.expect(:request, nil, [:multipart])
    faraday.expect(:request, nil, [:url_encoded])
    faraday.expect(:adapter, nil, [Faraday.default_adapter])
    connection.expect(:post, response) do |arg1, arg2|
      assert_equal path, arg1
      assert_equal payload[:mysubmit], arg2[:mysubmit]
      assert payload[:archive] === arg2[:archive]
    end
    response.expect(:status, 200)
    response.expect(:body, "Install Success")

    loader = RokuBuilder::Loader.new(**device_config)
    result = nil
    RokuBuilder::ManifestManager.stub(:build_version, "build_version") do
      loader.stub(:build, "zip_file") do
        Faraday.stub(:new, connection, faraday) do
          Faraday::UploadIO.stub(:new, io) do
            File.stub(:delete, nil) do
              result = loader.sideload(**loader_config)
            end
          end
        end
      end
    end

    assert_equal "build_version", result

    connection.verify
    faraday.verify
    io.verify
    response.verify
  end

  def test_loader_build_defining_folder_and_files
    root_dir = File.join(File.dirname(__FILE__), "test_files", "loader_test")
    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password"
    }
    build_config = {
      root_dir: root_dir,
      folders: ["source"],
      files: ["manifest"]
    }
    loader = RokuBuilder::Loader.new(**device_config)
    outfile = nil
    RokuBuilder::ManifestManager.stub(:build_version, "build_version") do
      outfile = loader.build(**build_config)
    end
    Zip::File.open(outfile) do |file|
      assert file.find_entry("manifest") != nil
      assert file.find_entry("source/a") != nil
      assert file.find_entry("source/b") != nil
      assert_nil file.find_entry("c")
    end
  end
  def test_loader_build_all_contents
    root_dir = File.join(File.dirname(__FILE__), "test_files", "loader_test")
    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password"
    }
    build_config = {
      root_dir: root_dir,
    }
    loader = RokuBuilder::Loader.new(**device_config)
    outfile = nil
    RokuBuilder::ManifestManager.stub(:build_version, "build_version") do
      outfile = loader.build(**build_config)
    end
    Zip::File.open(outfile) do |file|
      assert file.find_entry("manifest") != nil
      assert file.find_entry("source/a") != nil
      assert file.find_entry("source/b") != nil
      assert file.find_entry("c") != nil
    end
  end

  def test_loader_unload
    connection = Minitest::Mock.new
    faraday = Minitest::Mock.new
    response = Minitest::Mock.new

    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password"
    }
    payload = {
      mysubmit: "Delete",
      archive: "",
    }
    path = "/plugin_install"

    faraday.expect(:headers, {})
    faraday.expect(:request, nil, [:digest, device_config[:user], device_config[:password]])
    faraday.expect(:request, nil, [:multipart])
    faraday.expect(:request, nil, [:url_encoded])
    faraday.expect(:adapter, nil, [Faraday.default_adapter])
    connection.expect(:post, response) do |arg1, arg2|
      assert_equal path, arg1
      assert_equal payload[:mysubmit], arg2[:mysubmit]
      assert payload[:archive] === arg2[:archive]
    end
    response.expect(:status, 200)
    response.expect(:body, "Install Success")

    loader = RokuBuilder::Loader.new(**device_config)
    result = nil
    Faraday.stub(:new, connection, faraday) do
      result = loader.unload
    end

    assert_equal true, result

    connection.verify
    faraday.verify
    response.verify
  end
end
