# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder
  class Logger

    @@instance = nil

    def self.instance
      unless @@instance
        @@instance = ::Logger.new(STDOUT)
        @@instance.formatter = proc {|severity, datetime, _progname, msg|
          "[%s #%s] %5s: %s\n\r" % [datetime.strftime("%Y-%m-%d %H:%M:%S.%4N"), $$, severity, msg]
        }
      end
      @@instance
    end

    def self.set_debug
      instance.level = ::Logger::DEBUG
    end
    def self.set_info
      instance.level = ::Logger::INFO
    end
    def self.set_warn
      instance.level = ::Logger::WARN
    end

    def self.set_testing
      @@instance = ::Logger.new(File::NULL)
    end
  end
end
