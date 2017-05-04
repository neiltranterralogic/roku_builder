# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class UtilTest < Minitest::Test
    def test_util_init
      device_config = {
        ip: "111.222.333",
        user: "user",
        password: "password"
      }
      test = TestClass.new(**device_config)
      assert test.inited
    end
  end

  class TestClass < Util
    def init
      @inited = true
    end
    def inited
      @inited || false
    end
  end
end
