module RokuBuilder
  class Monitor

    def initialize(**device_config)
      @config = device_config
      @ports = {
        main: 8085,
        sg: 8089,
        task1: 8090,
        task2: 8090,
        task3: 8090,
        taskX: 8090,
      }
    end

    def monitor(type:)
      telnet_config = {
        'Host' => @config[:ip],
        'Port' => @ports[type]
      }
      waitfor_config = {
        'Match' => /./,
        'Timeout' => false
      }

      thread = Thread.new(telnet_config, waitfor_config) {|telnet_config,waitfor_config|
        puts "Monitoring #{type} console(#{telnet_config['Port']}) on #{telnet_config['Host'] }"
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
      while true
        puts "Q to exit"
        command = gets
        if command.chomp == "q"
          exit
        end
      end
    end
  end
end
