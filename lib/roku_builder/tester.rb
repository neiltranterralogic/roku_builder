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
      connection.waitfor(/\n/) do |txt|
        txt.split("\n").each do |line|
          in_tests = false if line =~ /\*\*\*\*\* ENDING TESTS \*\*\*\*\*/
          puts line if in_tests
          in_tests = true if line =~ /\*\*\*\*\* STARTING TESTS \*\*\*\*\*/
        end
      end
    end
  end
end
