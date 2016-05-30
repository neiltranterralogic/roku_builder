require_relative "test_helper.rb"

class LinkerTest < Minitest::Test
  def test_linker_link
    connection = Minitest::Mock.new
    faraday = Minitest::Mock.new
    response = Minitest::Mock.new

    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password",
      logger: Logger.new("/dev/null")
    }
    path = "/launch/dev?a=A&b=B%3AC&d=a%5Cb"
    options = 'a:A, b:B:C, d:a\b'

    connection.expect(:post, response, [path])
    faraday.expect(:headers, {})
    faraday.expect(:request, nil, [:digest, device_config[:user], device_config[:password]])
    faraday.expect(:request, nil, [:multipart])
    faraday.expect(:request, nil, [:url_encoded])
    faraday.expect(:adapter, nil, [Faraday.default_adapter])
    response.expect(:success?, true)

    linker = RokuBuilder::Linker.new(**device_config)
    success = nil
    Faraday.stub(:new, connection, faraday) do
      success = linker.launch(options: options)
    end

    assert success

    connection.verify
    faraday.verify
    response.verify
  end
  def test_linker_link_nothing
    logger = Minitest::Mock.new
    connection = Minitest::Mock.new
    faraday = Minitest::Mock.new
    response = Minitest::Mock.new

    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password",
      logger: logger
    }
    path = "/launch/dev"
    options = ''
    logger.expect(:warn, nil, ["No options sent to launched app"])
    connection.expect(:post, response, [path])
    faraday.expect(:headers, {})
    faraday.expect(:request, nil, [:digest, device_config[:user], device_config[:password]])
    faraday.expect(:request, nil, [:multipart])
    faraday.expect(:request, nil, [:url_encoded])
    faraday.expect(:adapter, nil, [Faraday.default_adapter])
    response.expect(:success?, true)
    linker = RokuBuilder::Linker.new(**device_config)
    success = nil
    Faraday.stub(:new, connection, faraday) do
      success = linker.launch(options: options)
    end

    assert success
    logger.verify
    connection.verify
    faraday.verify
    response.verify
  end

    assert !success

  end
end
