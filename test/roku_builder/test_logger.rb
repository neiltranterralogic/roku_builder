# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

class LoggerTest < Minitest::Test

  def test_logger
    logger_a = RokuBuilder::Logger.instance
    logger_b = RokuBuilder::Logger.instance
    assert_equal logger_a, logger_b
  end

  def test_set_debug
    logger = Minitest::Mock.new
    RokuBuilder::Logger.class_variable_set(:@@instance, logger)
    logger.expect(:level=, nil, [Logger::DEBUG])
    RokuBuilder::Logger.set_debug
    logger.verify
    RokuBuilder::Logger.set_testing
  end

  def test_set_info
    logger = Minitest::Mock.new
    RokuBuilder::Logger.class_variable_set(:@@instance, logger)
    logger.expect(:level=, nil, [Logger::INFO])
    RokuBuilder::Logger.set_info
    logger.verify
    RokuBuilder::Logger.set_testing
  end

  def test_set_warn
    logger = Minitest::Mock.new
    RokuBuilder::Logger.class_variable_set(:@@instance, logger)
    logger.expect(:level=, nil, [Logger::WARN])
    RokuBuilder::Logger.set_warn
    logger.verify
    RokuBuilder::Logger.set_testing
  end

  def test_logger_testing
    RokuBuilder::Logger.set_testing
    logger = RokuBuilder::Logger.instance
    assert_equal "/dev/null", logger.instance_variable_get(:@logdev).instance_variable_get(:@filename)
  end
end
