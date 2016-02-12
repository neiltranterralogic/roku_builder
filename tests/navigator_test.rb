require "roku_builder"
require "minitest/autorun"

class NavigatorTest < Minitest::Test
  def test_navigator_nav
    commands = {
      up: "Up",
      down: "Down",
      right: "Right",
      left: "Left",
      select: "Select",
      back: "Back",
      home: "Home",
      rew: "Rev",
      ff: "Fwd",
      play: "Play",
      replay: "InstantReplay"
    }
    commands.each {|k,v|
      path = "/keypress/#{v}"
      navigator_test(path: path, input: k, type: :nav)
    }
  end

  def test_navigator_type
    path = "keypress/LIT_"
    navigator_test(path: path, input: "Type", type: :text)
  end

  def navigator_test(path:, input:, type:)
    connection = Minitest::Mock.new
    faraday = Minitest::Mock.new
    io = Minitest::Mock.new
    response = Minitest::Mock.new

    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password"
    }
    if type == :nav
      connection.expect(:post, response, [path])
      response.expect(:success?, true)
    elsif type == :text
      input.split(//).each do |c|
        path = "/keypress/LIT_#{CGI::escape(c)}"
        connection.expect(:post, response, [path])
        response.expect(:success?, true)
      end
    end
    faraday.expect(:request, nil, [:multipart])
    faraday.expect(:request, nil, [:url_encoded])
    faraday.expect(:adapter, nil, [Faraday.default_adapter])

    navigator = RokuBuilder::Navigator.new(**device_config)
    success = nil
    Faraday.stub(:new, connection, faraday) do
      if type == :nav
        success = navigator.nav(command: input)
      elsif type == :text
        success = navigator.type(text: input)
      end
    end

    assert success

    connection.verify
    faraday.verify
    io.verify
    response.verify
  end
end
