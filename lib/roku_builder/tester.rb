module RokuBuilder
  class Tester

    def initialize(**device_config)
      @config = device_config
    end

    def run_tests(root_dir:, branch:)
      sideload_config = {
        root_dir: root_dir,
        branch: branch,
        update_manifest: false
      }
      telnet_config ={
        'Host' => @config[:ip],
        'Port' => 8085
      }

      loader = Loader.new(**@config)
      connection = Net::Telnet.new(telnet_config)
      loader.sideload(**sideload_config)

      in_tests = false
      end_reg = /\*\*\*\*\* ENDING TESTS \*\*\*\*\*/
      connection.waitfor(end_reg) do |txt|
        txt.split("\n").each do |line|
          in_tests = false if line =~ end_reg
          puts line if in_tests
          in_tests = true if line =~ /\*\*\*\*\* STARTING TESTS \*\*\*\*\*/
        end
      end
      connection.puts("cont\n")
    end
  end
end
