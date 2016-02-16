module RokuBuilder

  MISSING_DEVICES = 1
  MISSING_DEVICES_DEFAULT = 2
  DEVICE_DEFAULT_BAD = 3
  MISSING_PROJECTS = 4
  MISSING_PROJECTS_DEFAULT = 5
  PROJECTS_DEFAULT_BAD = 6
  DEVICE_MISSING_IP = 7
  DEVICE_MISSING_USER = 8
  DEVICE_MISSING_PASSWORD = 9
  PROJECT_MISSING_APP_NAME = 10
  PROJECT_MISSING_DIRECTORY = 11
  PROJECT_MISSING_FOLDERS = 12
  PROJECT_FOLDERS_BAD = 13
  PROJECT_MISSING_FILES = 14
  PROJECT_FILES_BAD = 15
  STAGE_MISSING_BRANCH = 16

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
      codes.push(MISSING_DEVICES) if not config[:devices]
      codes.push(MISSING_DEVICES_DEFAULT) if config[:devices] and not config[:devices][:default]
      codes.push(DEVICE_DEFAULT_BAD) if config[:devices] and config[:devices][:default] and not config[:devices][:default].is_a?(Symbol)
      codes.push(MISSING_PROJECTS) if not config[:projects]
      codes.push(MISSING_PROJECTS_DEFAULT) if config[:projects] and not config[:projects][:default]
      codes.push(MISSING_PROJECTS_DEFAULT) if config[:projects] and config[:projects][:default] == "<project id>".to_sym
      codes.push(PROJECTS_DEFAULT_BAD) if config[:projects] and config[:projects][:default] and not config[:projects][:default].is_a?(Symbol)
      if config[:devices]
        config[:devices].each {|k,v|
          next if k == :default
          codes.push(DEVICE_MISSING_IP) if not v[:ip]
          codes.push(DEVICE_MISSING_IP) if v[:ip] == "xxx.xxx.xxx.xxx"
          codes.push(DEVICE_MISSING_IP) if v[:ip] == ""
          codes.push(DEVICE_MISSING_USER) if not v[:user]
          codes.push(DEVICE_MISSING_USER) if v[:user] == "<username>"
          codes.push(DEVICE_MISSING_USER) if v[:user] == ""
          codes.push(DEVICE_MISSING_PASSWORD) if not v[:password]
          codes.push(DEVICE_MISSING_PASSWORD) if v[:password] == "<password>"
          codes.push(DEVICE_MISSING_PASSWORD) if v[:password] == ""
        }
      end
      if config[:projects]
        config[:projects].each {|k,v|
          next if k == :default
          codes.push(PROJECT_MISSING_APP_NAME) if not v[:app_name]
          codes.push(PROJECT_MISSING_DIRECTORY) if not v[:directory]
          codes.push(PROJECT_MISSING_FOLDERS) if not v[:folders]
          codes.push(PROJECT_FOLDERS_BAD) if v[:folders] and not v[:folders].is_a?(Array)
          codes.push(PROJECT_MISSING_FILES) if not v[:files]
          codes.push(PROJECT_FILES_BAD) if v[:files] and not v[:files].is_a?(Array)
          v[:stages].each {|k,v|
            codes.push(STAGE_MISSING_BRANCH) if not v[:branch]
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
