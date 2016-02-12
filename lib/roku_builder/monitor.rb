module RokuBuilder

  # Monitor development Logs
  class Monitor < Util

    # Initialize port config
    def init()
      @ports = {
        main: 8085,
        sg: 8089,
        task1: 8090,
        task2: 8090,
        task3: 8090,
        taskX: 8090,
      }
    end

    # Monitor a development log on the Roku device
    # @param type [Symbol] The log type to monitor
    # @param verbose [Boolean] Print status messages.
    def monitor(type:, verbose: true)
      telnet_config = {
        'Host' => @roku_ip_address,
        'Port' => @ports[type]
      }
      waitfor_config = {
        'Match' => /./,
        'Timeout' => false
      }

      thread = Thread.new(telnet_config, waitfor_config) {|telnet_config,waitfor_config|
        puts "Monitoring #{type} console(#{telnet_config['Port']}) on #{telnet_config['Host'] }" if verbose
        connection = Net::Telnet.new(telnet_config)
        all_text = ""
        while true
          connection.waitfor(waitfor_config) do |txt|
            all_text += txt
            while line = all_text.slice!(/^.*\n/) do
              puts line
            end
          end
        end
      }
      running = true
      while running
        puts "Q to exit" if verbose
        command = gets
        if command.chomp == "q"
          thread.exit
          running = false
        end
      end
    end
  end
end
