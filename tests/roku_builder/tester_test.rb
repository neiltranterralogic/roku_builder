require "roku_builder"
require "minitest/autorun"

class TesterTest < Minitest::Test
  def test_tester_runtests
    connection = Minitest::Mock.new
    loader = Minitest::Mock.new
    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password"
    }
    test_config = {
      root_dir: "root",
      branch: "branch"
    }
    tester = RokuBuilder::Tester.new(**device_config)

    loader.expect(:sideload, nil, [test_config])
    connection.expect(:waitfor, nil, [/\*\*\*\*\* ENDING TESTS \*\*\*\*\*/])
    connection.expect(:puts, nil, ["cont\n"])

    RokuBuilder::Loader.stub(:new, loader) do
      Net::Telnet.stub(:new, connection) do
        tester.run_tests(**test_config)
      end
    end

    connection.verify
  end
end
