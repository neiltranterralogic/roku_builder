module RokuBuilder

  # Load and validate config files.
  class ConfigManager

    # Loads the roku config from file
    # @param config [String] path for the roku config
    # @return [Hash] roku config object
    def self.get_config(config:, logger:)
      begin
        config = JSON.parse(File.open(config).read, {symbolize_names: true})
        config[:devices][:default] = config[:devices][:default].to_sym
        config[:projects][:default] = config[:projects][:default].to_sym
        config
      rescue JSON::ParserError
        logger.fatal "Config file is not valid JSON"
        nil
      end
    end

    # Validates the roku config
    # @param config [Hash] roku config object
    # @return [Array] error codes for valid config (see self.error_codes)
    def self.validate_config(config:, logger:)
      codes = []
      codes.push(1) if not config[:devices]
      codes.push(2) if config[:devices] and not config[:devices][:default]
      codes.push(3) if config[:devices] and config[:devices][:default] and not config[:devices][:default].is_a?(Symbol)
      codes.push(4) if not config[:projects]
      codes.push(5) if config[:projects] and not config[:projects][:default]
      codes.push(5) if config[:projects] and config[:projects][:default] == "<project id>".to_sym
      codes.push(6) if config[:projects] and config[:projects][:default] and not config[:projects][:default].is_a?(Symbol)
      if config[:devices]
        config[:devices].each {|k,v|
          next if k == :default
          codes.push(7) if not v[:ip]
          codes.push(7) if v[:ip] == "xxx.xxx.xxx.xxx"
          codes.push(7) if v[:ip] == ""
          codes.push(8) if not v[:user]
          codes.push(8) if v[:user] == "<username>"
          codes.push(8) if v[:user] == ""
          codes.push(9) if not v[:password]
          codes.push(9) if v[:password] == "<password>"
          codes.push(9) if v[:password] == ""
        }
      end
      if config[:projects]
        config[:projects].each {|k,v|
          next if k == :default
          codes.push(10) if not v[:app_name]
          codes.push(11) if not v[:directory]
          codes.push(12) if not v[:folders]
          codes.push(13) if v[:folders] and not v[:folders].is_a?(Array)
          codes.push(14) if not v[:files]
          codes.push(15) if v[:files] and not v[:files].is_a?(Array)
          v[:stages].each {|k,v|
            codes.push(16) if not v[:branch]
          }
        }
      end
      codes.push(0) if codes.empty?
      codes
    end

    # Error code messages for config validation
    # @return [Array] error code messages
    def self.error_codes()
      [
        #===============FATAL ERRORS===============#
        "Valid Config.",
        "Devices config is missing.",
        "Devices default is missing.",
        "Devices default is not a hash.",
        "Projects config is missing.",
        "Projects default is missing.", #5
        "Projects default is not a hash.",
        "A device config is missing its IP address.",
        "A device config is missing its username.",
        "A device config is missing its password.",
        "A project config is missing its app_name.", #10
        "A project config is missing its directorty.",
        "A project config is missing its folders.",
        "A project config's folders is not an array.",
        "A project config is missing its files.",
        "A project config's files is not an array.", #15
        "A project stage is missing its branch."
        #===============WARNINGS===============#
      ]
    end

    # Edit the roku config
    # @param config [String] path for the roku config
    # @param options [String] options to set in the config
    # @param device [String] which device to use
    # @param project [String] which project to use
    # @param stage[String] which stage to use
    # @return [Boolean] success
    def self.edit_config(config:, options:, device:, project:, stage:, logger:)
      config_object = get_config(config: config, logger: logger)
      return false unless config_object
      unless project
        project = config_object[:projects][:default]
      else
        project = project.to_sym
      end
      unless device
        device = config_object[:devices][:default]
      else
        device = device.to_sym
      end
      unless stage
        stage = :production
      else
        stage = stage.to_sym
      end
      changes = {}
      opts = options.split(/,\s*/)
      opts.each do |opt|
        opt = opt.split(":")
        key = opt.shift.to_sym
        value = opt.join(":")
        changes[key] = value
      end
      changes.each {|key,value|
        if [:ip, :user, :password].include?(key)
          config_object[:devices][device][key] = value
        elsif [:directory, :app_name].include?(key) #:folders, :files
          config_object[:projects][project][key] = value
        elsif [:branch]
          config_object[:projects][project][:stages][stage][key] = value
        end
      }
      config_string = JSON.pretty_generate(config_object)
      file = File.open(config, "w")
      file.write(config_string)
      file.close
      return true
    end
  end
end
