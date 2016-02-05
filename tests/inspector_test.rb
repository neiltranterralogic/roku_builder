require "roku_builder"
require "minitest/autorun"
require 'byebug'

class InspectorTest < Minitest::Test
  def test_inspector_inspect
    connection = Minitest::Mock.new
    faraday = Minitest::Mock.new
    io = Minitest::Mock.new
    response = Minitest::Mock.new

    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password"
    }
    path = "/plugin_inspect"
    password = "password"
    payload ={
      mysubmit: "Inspect",
      password: password,
      archive: io
    }
    body = "<td>App Name:</td><td><font>app_name</font></td>"+
           "<td>Dev ID:</td><td><font>dev_id</font></td>"+
           "<td>Creation Date:</td><td><font><script>var d = new Date(628232400)</script></font></td>"+
           "<td>dev.zip:</td><td><font>dev_zip</font></td>"

    connection.expect(:post, response) do |arg1, arg2|
      assert_equal path, arg1
      assert_equal payload[:mysubmit], arg2[:mysubmit]
      assert_equal payload[:password], arg2[:passwd]
      assert payload[:archive] === arg2[:archive]
    end
    faraday.expect(:request, nil, [:digest, device_config[:user], device_config[:password]])
    faraday.expect(:request, nil, [:multipart])
    faraday.expect(:request, nil, [:url_encoded])
    faraday.expect(:adapter, nil, [Faraday.default_adapter])
    response.expect(:body, body)
    response.expect(:body, body)
    response.expect(:body, body)
    response.expect(:body, body)


    package_info = {}
    inspector = RokuBuilder::Inspector.new(**device_config)
    Faraday.stub(:new, connection, faraday) do
      Faraday::UploadIO.stub(:new, io) do
        package_info = inspector.inspect(pkg: "pkg/path", password: password)
      end
    end

    assert_equal "app_name", package_info[:app_name]
    assert_equal "dev_id", package_info[:dev_id]
    assert_equal Time.at(628232400).to_s, package_info[:creation_date]
    assert_equal "dev_zip", package_info[:dev_zip]

    connection.verify
    faraday.verify
    io.verify
    response.verify
  end
end
