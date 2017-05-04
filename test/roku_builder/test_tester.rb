# ********** Copyright Viacom, Inc. Apache 2.0 **********
require_relative "test_helper.rb"

module RokuBuilder
  class TesterTest < Minitest::Test
    def test_tester_runtests
      connection = Minitest::Mock.new
      loader = Minitest::Mock.new
      linker = Minitest::Mock.new
      device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password",
        init_params: {root_dir: "root/dir/path"}
      }
      loader_config = {
        root_dir: "root/dir/path",
        branch: "branch",
        folders: ["source"],
        files: ["manifest"]
      }
      tester = Tester.new(**device_config)

      loader.expect(:sideload, [SUCCESS, ""], [loader_config])
      linker.expect(:launch, nil, [{options: "RunTests:true"}])
      connection.expect(:waitfor, nil, [/\*+\s*End testing\s*\*+/])
      connection.expect(:puts, nil, ["cont\n"])

      Loader.stub(:new, loader) do
        Linker.stub(:new, linker) do
          Net::Telnet.stub(:new, connection) do
            tester.run_tests(sideload_config: loader_config)
          end
        end
      end

      connection.verify
    end

    def test_tester_runtests_and_handle
      waitfor = Proc.new do |end_reg, &blk|
      assert_equal(/\*+\s*End testing\s*\*+/, end_reg)
      txt = "Fake Text"
      blk.call(txt) == false
      end
      connection = Minitest::Mock.new
      loader = Minitest::Mock.new
      linker = Minitest::Mock.new
      device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password",
        init_params: {root_dir: "root/dir/path"}
      }
      loader_config = {
        root_dir: "root/dir/path",
        branch: "branch",
        folders: ["source"],
        files: ["manifest"]
      }
      tester = Tester.new(**device_config)

      loader.expect(:sideload, [SUCCESS, ""], [loader_config])
      linker.expect(:launch, nil, [{options: "RunTests:true"}])
      connection.expect(:waitfor, nil, &waitfor)
      connection.expect(:puts, nil, ["cont\n"])

      Loader.stub(:new, loader) do
        Net::Telnet.stub(:new, connection) do
          Linker.stub(:new, linker) do
            tester.stub(:handle_text, false) do
              tester.run_tests(sideload_config: loader_config)
            end
          end
        end
      end

      connection.verify
    end

    def test_tester_handle_text_no_text
      device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password",
        init_params: {root_dir: "root/dir/path"}
      }
      tester = Tester.new(**device_config)

      text = "this\nis\na\ntest\nparagraph"
      tester.send(:handle_text, {txt: text})

      refute tester.instance_variable_get(:@in_tests)
    end

    def test_tester_handle_text_all_text
      device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password",
        init_params: {root_dir: "root/dir/path"}
      }
      tester = Tester.new(**device_config)
      tester.instance_variable_set(:@in_tests, true)

      text = ["this","is","a","test","paragraph"]

      tester.send(:handle_text, {txt: text.join("\n")})
      assert_equal text, tester.instance_variable_get(:@logs)
      assert tester.instance_variable_get(:@in_tests)
    end

    def test_tester_handle_text_partial_text
      device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password",
        init_params: {root_dir: "root/dir/path"}
      }
      tester = Tester.new(**device_config)

      text = ["this","*Start testing*","is","a","test","*End testing*","paragraph"]
      verify_text = ["***************","***************","*Start testing*","is","a","test","*End testing*","*************","*************"]

      tester.send(:handle_text, {txt: text.join("\n")})
      refute tester.instance_variable_get(:@in_tests)
      assert_equal verify_text, tester.instance_variable_get(:@logs)
    end
  end
end
