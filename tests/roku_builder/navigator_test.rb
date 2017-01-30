# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

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

  def test_navigator_nav_fail
    path = ""
    navigator_test(path: path, input: :bad, type: :nav, success: false)
  end

  def test_navigator_type
    path = "keypress/LIT_"
    navigator_test(path: path, input: "Type", type: :text)
  end

  def navigator_test(path:, input:, type:, success: true)
    connection = Minitest::Mock.new
    faraday = Minitest::Mock.new
    io = Minitest::Mock.new
    response = Minitest::Mock.new

    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password",
      logger: Logger.new("/dev/null"),
      init_params: {mappings: {}}
    }
    if success
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
      faraday.expect(:headers, {})
      faraday.expect(:request, nil, [:digest, device_config[:user], device_config[:password]])
      faraday.expect(:request, nil, [:multipart])
      faraday.expect(:request, nil, [:url_encoded])
      faraday.expect(:adapter, nil, [Faraday.default_adapter])
    end if

    navigator = RokuBuilder::Navigator.new(**device_config)
    result = nil
    Faraday.stub(:new, connection, faraday) do
      if type == :nav
        result = navigator.nav(commands: [input])
      elsif type == :text
         result = navigator.type(text: input)
      end
    end

    assert_equal success, result

    connection.verify
    faraday.verify
    io.verify
    response.verify
  end

  def test_navigator_screen
    logger = Minitest::Mock.new
    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password",
      logger: logger,
      init_params: {mappings: {}}
    }
    navigator = RokuBuilder::Navigator.new(**device_config)

    logger.expect(:info, nil, ["Home x 5, Fwd x 3, Rev x 2,"])
    logger.expect(:unknown, nil, ["Cannot run command automatically"])
    logger.expect(:unknown, nil, ["Home x 5, Up, Rev x 2, Fwd x 2,"])

    navigator.stub(:nav, nil) do
      navigator.screen(type: :secret)
      navigator.screen(type: :reboot)
    end

    logger.verify
  end

  def test_navigator_screen_fail
    logger = Minitest::Mock.new
    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password",
      logger: logger,
      init_params: {mappings: {}}
    }
    navigator = RokuBuilder::Navigator.new(**device_config)

    assert !navigator.screen(type: :bad)

    logger.verify
  end

  def test_navigator_screens
    logger = Minitest::Mock.new
    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password",
      logger: logger,
      init_params: {mappings: {}}
    }
    navigator = RokuBuilder::Navigator.new(**device_config)

    navigator.instance_variable_get("@screens").each_key do |key|
      logger.expect(:unknown, nil, [key])
    end

    navigator.screens

    logger.verify
  end

  def test_navigator_read_char
    getc = Minitest::Mock.new
    chr = Minitest::Mock.new

    getc.expect(:call, chr)
    chr.expect(:chr, "a")

    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password",
      logger: Logger.new("/dev/null"),
      init_params: {mappings: {}}
    }

    navigator = RokuBuilder::Navigator.new(**device_config)
    STDIN.stub(:echo=, nil) do
      STDIN.stub(:raw!, nil) do
        STDIN.stub(:getc, getc) do
          assert_equal "a", navigator.read_char
        end
      end
    end
    getc.verify
    chr.verify
  end

  def test_navigator_read_char_multichar
    getc = Minitest::Mock.new
    chr = Minitest::Mock.new
    read_nonblock = Minitest::Mock.new

    getc.expect(:call, chr)
    chr.expect(:chr, "\e")
    read_nonblock.expect(:call, "a", [3])
    read_nonblock.expect(:call, "b", [2])

    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password",
      logger: Logger.new("/dev/null"),
      init_params: {mappings: {}}
    }

    navigator = RokuBuilder::Navigator.new(**device_config)
    STDIN.stub(:echo=, nil) do
      STDIN.stub(:raw!, nil) do
        STDIN.stub(:getc, getc) do
          STDIN.stub(:read_nonblock, read_nonblock) do
            assert_equal "\eab", navigator.read_char
          end
        end
      end
    end
    getc.verify
    chr.verify
  end

  def test_navigator_interactive
    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password",
      logger: Logger.new("/dev/null"),
      init_params: {mappings: {}}
    }
    navigator = RokuBuilder::Navigator.new(**device_config)
    navigator.stub(:read_char, "\u0003") do
      navigator.interactive
    end
  end

  def test_navigator_interactive_nav

    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password",
      logger: Logger.new("/dev/null"),
      init_params: {mappings: {}}
    }

    read_char = lambda {
      @i ||= 0
      char = nil
      case(@i)
      when 0
        char = "<"
      when 1
        char = "\u0003"
      end
      @i += 1
      char
    }

    nav = lambda { |args|
      assert_equal :rev, args[:commands][0]
    }

    navigator = RokuBuilder::Navigator.new(**device_config)
    navigator.stub(:read_char, read_char) do
      navigator.stub(:nav, nav) do
        navigator.interactive
      end
    end
  end
  def test_navigator_interactive_text

    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password",
      logger: Logger.new("/dev/null"),
      init_params: {mappings: {}}
    }

    read_char = lambda {
      @i ||= 0
      char = nil
      case(@i)
      when 0
        char = "a"
      when 1
        char = "\u0003"
      end
      @i += 1
      char
    }

    type = lambda { |args|
      assert_equal "a", args[:text]
    }

    navigator = RokuBuilder::Navigator.new(**device_config)
    navigator.stub(:read_char, read_char) do
      navigator.stub(:type, type) do
        navigator.interactive
      end
    end
  end
end
