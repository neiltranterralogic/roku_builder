require "roku_builder"
require "minitest/autorun"

class MonitorTest < Minitest::Test
  def test_monitor_monit
    connection = Minitest::Mock.new
    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password",
      logger: Logger.new("/dev/null")
    }
    monitor_config = {
      'Host' => device_config[:ip],
      'Post' => 8085
    }
    monitor = RokuBuilder::Monitor.new(**device_config)

    connection.expect(:waitfor, nil) do |config|
      assert_equal /./, config['Match']
      assert_equal false, config['Timeout']
    end

    def monitor.gets
      sleep(0.1)
      "q"
    end

    Net::Telnet.stub(:new, connection) do
      monitor.monitor(type: :main, verbose: false)
    end

    connection.verify
  end
end
