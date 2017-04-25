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

    def self.set_testing
      @@instance = ::Logger.new("/dev/null")
    end
  end
end
