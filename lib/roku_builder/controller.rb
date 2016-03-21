module RokuBuilder

  # Controls all interaction with other classes
  class Controller

    # Run the builder
    # @param options [Hash] The options hash
    def self.run(options:)
      logger = Logger.new(STDOUT)
      logger.formatter = proc {|severity, datetime, progname, msg|
        "[%s #%s] %5s: %s\n\r" % [datetime.strftime("%Y-%m-%d %H:%M:%S.%4N"), $$, severity, msg]
      }
      if options[:debug]
        logger.level = Logger::DEBUG
      elsif options[:verbose]
        logger.level = Logger::INFO
      else
        logger.level = Logger::WARN
      end

      # Validate Options
      options_code = validate_options(options: options, logger: logger)
      ErrorHandler.handle_options_codes(options: options, options_code: options_code, logger: logger)

      # Configure Gem
      configure_code = configure(options: options, logger: logger)
      ErrorHandler.handle_configure_codes(options: options, configure_code: configure_code, logger: logger)

      # Load Config
      load_code, config, configs = ConfigManager.load_config(options: options, logger: logger)
      ErrorHandler.handle_load_codes(options: options, load_code: load_code, logger: logger)

      # Check devices
      device_code, configs = check_devices(options: options, config: config, configs: configs, logger: logger)
      ErrorHandler.handle_device_codes(options: options, device_code: device_code, logger: logger)

      # Run Commands
      command_code = execute_commands(options: options, config: config, configs: configs, logger: logger)
      ErrorHandler.handle_command_codes(options: options, command_code: command_code, logger: logger)
    end

    protected

    # Validates the commands
    # @param options [Hash] The options hash
    # @return [Integer] Status code for command validation
    # @param logger [Logger] system logger
    def self.validate_options(options:, logger:)
      commands = options.keys & self.commands
      return EXTRA_COMMANDS if commands.count > 1
      return NO_COMMANDS if commands.count < 1
      sources = options.keys & self.sources
      return EXTRA_SOURCES if sources.count > 1
      if (options.keys & self.source_commands).count == 1
        return NO_SOURCE unless sources.count == 1
      end
      if sources.include?(:current)
        return BAD_CURRENT unless options[:build] or options[:sideload]
      end
      if options[:in]
        return BAD_IN_FILE unless options[:sideload]
      end
      if options[:deeplink]
        return BAD_DEEPLINK if !options[:deeplink_options] or options[:deeplink_options].chomp == ""
      end
      return VALID
    end

    # Run commands
    # @param options [Hash] The options hash
    # @return [Integer] Return code for options handeling
    # @param logger [Logger] system logger
    def self.execute_commands(options:, config:, configs:, logger:)
      command = (self.commands & options.keys).first
      if ControllerCommands.simple_commands.keys.include?(command)
        params = ControllerCommands.simple_commands[command]
        params[:configs] = configs
        ControllerCommands.simple_command(**params)
      else
        params = ControllerCommands.method(command.to_s).parameters.collect{|a|a[1]}
        args = {}
        params.each do |key|
          case key
          when :options
            args[:options] = options
          when :config
            args[:config] = config
          when :configs
            args[:configs] = configs
          when :logger
            args[:logger] = logger
          end
        end
        ControllerCommands.send(command, args)
      end
    end

    # Ensure that the selected device is accessable
    # @param options [Hash] The options hash
    # @param logger [Logger] system logger
    def self.check_devices(options:, config:, configs:, logger:)
      ping = Net::Ping::External.new
      host = configs[:device_config][:ip]
      return [GOOD_DEVICE, configs] if ping.ping? host, 1, 0.2, 1
      return [BAD_DEVICE, nil] if options[:device_given]
      config[:devices].each_pair {|key, value|
        unless key == :default
          host = value[:ip]
          if ping.ping? host, 1, 0.2, 1
            configs[:device_config] = value
            configs[:device_config][:logger] = logger
            return [CHANGED_DEVICE, configs]
          end
        end
      }
      return [NO_DEVICES, nil]
    end

    # List of command options
    # @return [Array<Symbol>] List of command symbols that can be used in the options hash
    def self.commands
      [:sideload, :package, :test, :deeplink,:configure, :validate, :delete,
        :navigate, :text, :build, :monitor, :update, :screencapture, :screen,
        :screens]
    end

    # List of source options
    # @return [Array<Symbol>] List of source symbols that can be used in the options hash
    def self.sources
      [:ref, :set_stage, :working, :current]
    end

    # List of commands requiring a source option
    # @return [Array<Symbol>] List of command symbols that require a source in the options hash
    def self.source_commands
      [:sideload, :package, :test, :build]
    end


    # Configure the gem
    # @param options [Hash] The options hash
    # @return [Integer] Success or failure code
    # @param logger [Logger] system logger
    def self.configure(options:, logger:)
      if options[:configure]
        source_config = File.expand_path(File.join(File.dirname(__FILE__), "..", '..', 'config.json.example'))
        target_config = File.expand_path(options[:config])
        if File.exist?(target_config)
          unless options[:edit_params]
            return CONFIG_OVERWRITE
          end
        else
          ### Copy Config File ###
          FileUtils.copy(source_config, target_config)
        end
        if options[:edit_params]
          ConfigManager.edit_config(config: target_config, options: options[:edit_params], device: options[:device], project: options[:project], stage: options[:stage], logger: logger)
        end
        return SUCCESS
      end
      nil
    end

    # Run a system command
    # @param command [String] The command to be run
    # @return [String] The output of the command
    def self.system(command:)
      `#{command}`.chomp
    end
  end
end
