# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder

  # Method for running unit tests
  # This is intended to be used with the brstest library but should work
  # with other testing libraries
  class Tester < Util

    # Initialize starting and ending regular expressions
    def init()
      @end_reg = /\*\*\*\*\* ENDING TESTS \*\*\*\*\*/
      @start_reg = /\*\*\*\*\* STARTING TESTS \*\*\*\*\*/
    end

    # Run tests and report results
    # @param sideload_config [Hash] The config for sideloading the app
    def unit_tests(sideload_config:)
      telnet_config ={
        'Host' => @roku_ip_address,
        'Port' => 8085
      }

      loader = Loader.new(**@device_config)
      connection = Net::Telnet.new(telnet_config)
      code, _build_version = loader.sideload(**sideload_config)

      if code = SUCCESS
        in_tests = false
        connection.waitfor(@end_reg) do |txt|
          in_tests = handle_unit_test_text(txt: txt, in_tests: in_tests)
        end
        connection.puts("cont\n")
      end
    end

    # Run intergration tests
    # @param sideload_config [Hash] The config for sideloading the app
    def intergration_tests(sideload_config:)
      telnet_config ={
        'Host' => @roku_ip_address,
        'Port' => 8085
      }
      waitfor_config = {
        'Match' => /./,
        'Timeout' => false
      }

      loader = Loader.new(**@device_config)
      connection = Net::Telnet.new(telnet_config)
      code, _build_version = loader.sideload(**sideload_config)

      if code = SUCCESS
        running = false
        all_txt = ""
        while running
          connection.waitfor(waitfor_config) do |txt|
            running, all_txt = handle_intergration_test_text(all_txt: all_txt,
              txt: txt)
          end
        end
      end
    end


    private

    # Handel unit testing text
    # @param txt [String] current text from telnet
    # @param in_tests [Boolean] currently parsing test text
    # @return [Boolean] currently parsing test text
    def handle_unit_test_text(txt:, in_tests:)
      txt.split("\n").each do |line|
        in_tests = false if line =~ @end_reg
        @logger.unknown line if in_tests
        in_tests = true if line =~ @start_reg
      end
      in_tests
    end

    # Handel intergration testing text
    # @param txt [String] current text from telnet
    # @param running [Boolean] currently parsing test text
    # @return [Boolean, String] currently parsing test text, remainder text
    def parse_intergration_test_text(all_txt:, txt:)
      all_txt += txt
      while line = all_txt.slice!(/^.*\n/) do
        if !line.strip.empty?
          parts = line.split()
          if match = parts[0] =~ /^ROKUTESTING\[([^\]]*)\]:$/
            beacon = {}
            beacon[:timestamp] = DateTime.parse(match[1])
            parts.each_index do |i|
              if parts[i] =~ /^id:$/
                beacon[:id] = parts[i+1]
              elsif parts[i] =~ /^delay:$/
                beacon[:delay] = parts[i+1]
              elsif parts[i] =~ /^bitmask:$/
                beacon[:bitmask] = parts[i+1]
              end
            end
            beacon[:type] = parts[1]
            case parts[1]
            when "start", "mark", "end", "cov_start", "cov_end"
              beacon[:suite] = parts[2]
            when "command"
              beacon[:commands] = parts[2]
              beacon[:suite] = parts[3]
            end
          end
        end
      end
      all_text
    end
  end
end
