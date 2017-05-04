# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class ProfilerTest < Minitest::Test
    def test_profiler_stats
      waitfor = Proc.new do |config, &blk|
      assert_equal(/.+/, config["Match"])
      assert_equal(5, config["Timeout"])
      txt = "<All_Nodes><NodeA /><NodeB /><NodeC><NodeD /></NodeC></All_Nodes>\n"
      blk.call(txt)
      true
      end
      connection = Minitest::Mock.new
      device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password"
      }
      profiler = Profiler.new(**device_config)

      connection.expect(:puts, nil, ["sgnodes all\n"])
      connection.expect(:waitfor, nil, &waitfor)

      Net::Telnet.stub(:new, connection) do
        profiler.stub(:printf, nil) do
          profiler.run(command: :stats)
        end
      end

      connection.verify
    end
  end
end
