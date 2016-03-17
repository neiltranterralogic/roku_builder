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
