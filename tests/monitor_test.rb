require "roku_builder"
require "minitest/autorun"

class MonitorTest < Minitest::Test
  #TODO
  def test_monitor_monit
    device_config = {
      ip: "111.222.333",
      user: "user",
      password: "password"
    }
    monitor = RokuBuilder::Monitor.new(**device_config)
  end
end
