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
      handle_options_codes(options: options, options_code: options_code, logger: logger)

      # Configure Gem
      configure_code = configure(options: options, logger: logger)
      handle_configure_codes(options: options, configure_code: configure_code, logger: logger)

      # Load Config
      load_code, config, configs = ConfigManager.load_config(options: options, logger: logger)
      handle_load_codes(options: options, load_code: load_code, logger: logger)

      # Check devices
      device_code, configs = check_devices(options: options, config: config, configs: configs, logger: logger)
      handle_device_codes(options: options, device_code: device_code, logger: logger)

      # Run Commands
      command_code = execute_commands(options: options, logger: logger)
      handle_command_codes(options: options, command_code: command_code, logger: logger)
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
      case command
      when :validate
        # Do Nothing #
      when :sideload
        ### Sideload App ###
        loader = Loader.new(**configs[:device_config])
        success = loader.sideload(**configs[:sideload_config])
        return FAILED_SIDELOAD unless success
      when :package
        ### Package App ###
        keyer = Keyer.new(**configs[:device_config])
        loader = Loader.new(**configs[:device_config])
        packager = Packager.new(**configs[:device_config])
        inspector = Inspector.new(**configs[:device_config])
        logger.warn "Packaging working directory" if options[:working]
        # Sideload #
        build_version = loader.sideload(**configs[:sideload_config])
        return FAILED_SIGNING unless build_version
        # Key #
        success = keyer.rekey(**configs[:key])
        logger.info "Key did not change" unless success
        # Package #
        options[:build_version] = build_version
        configs = self.update_configs(configs: configs, options: options)
        success = packager.package(**configs[:package_config])
        logger.info "Signing Successful: #{configs[:package_config][:out_file]}" if success
        return FAILED_SIGNING unless success
        # Inspect #
        if options[:inspect]
          info = inspector.inspect(configs[:inspect_config])
          logger.unknown "App Name: #{info[:app_name]}"
          logger.unknown "Dev ID: #{info[:dev_id]}"
          logger.unknown "Creation Date: #{info[:creation_date]}"
          logger.unknown "dev.zip: #{info[:dev_zip]}"
        end
      when :build
        ### Build ###
        loader = Loader.new(**configs[:device_config])
        build_version = ManifestManager.build_version(**configs[:manifest_config])
        options[:build_version] = build_version
        configs = self.update_configs(configs: configs, options: options)
        outfile = loader.build(**configs[:build_config])
        logger.info "Build: #{outfile}"
      when :update
        ### Update ###
        old_version = ManifestManager.build_version(**configs[:manifest_config])
        new_version = ManifestManager.update_build(**configs[:manifest_config])
        logger.info "Update build version from:\n#{old_version}\nto:\n#{new_version}"
      when :deeplink
        ### Deeplink ###
        linker = Linker.new(**configs[:device_config])
        success = linker.link(**configs[:deeplink_config])
        return FAILED_DEEPLINKING unless success
      when :delete
        loader = Loader.new(**configs[:device_config])
        loader.unload()
      when :monitor
        monitor = Monitor.new(**configs[:device_config])
        monitor.monitor(**configs[:monitor_config])
      when :navigate
        navigator = Navigator.new(**configs[:device_config])
        success = navigator.nav(**configs[:navigate_config])
        return FAILED_NAVIGATING unless success
      when :screen
        navigator = Navigator.new(**configs[:device_config])
        success = navigator.screen(**configs[:screen_config])
        return FAILED_NAVIGATING unless success
      when :screens
        navigator = Navigator.new(**configs[:device_config])
        navigator.screens
      when :text
        navigator = Navigator.new(**configs[:device_config])
        navigator.type(**configs[:text_config])
      when :test
        tester = Tester.new(**configs[:device_config])
        tester.run_tests(**configs[:test_config])
      when :screencapture
        inspector = Inspector.new(**configs[:device_config])
        success = inspector.screencapture(**configs[:screencapture_config])
        return FAILED_SCREENCAPTURE unless success
      end
      return SUCCESS
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

    # Handle codes returned from validating options
    # @param options_code [Integer] the error code returned by validate_options
    # @param logger [Logger] system logger
    def self.handle_options_codes(options:, options_code:, logger:)
      case options_code
      when EXTRA_COMMANDS
        logger.fatal "Only one command is allowed"
        abort
      when NO_COMMANDS
        logger.fatal "At least one command is required"
        abort
      when EXTRA_SOURCES
        logger.fatal "Only use one of --ref, --working, --current or --stage"
        abort
      when NO_SOURCE
        logger.fatal "Must use at least one of --ref, --working, --current or --stage"
        abort
      when BAD_CURRENT
        logger.fatal "Can only sideload or build 'current' directory"
        abort
      when BAD_DEEPLINK
        logger.fatal "Must supply deeplinking options when deeplinking"
        abort
      when BAD_IN_FILE
        logger.fatal "Can only supply in file for building"
        abort
      end
    end

    # Handle codes returned from configuring
    # @param configure_code [Integer] the error code returned by configure
    # @param logger [Logger] system logger
    def self.handle_configure_codes(options:, configure_code:, logger:)
      case configure_code
      when CONFIG_OVERWRITE
        logger.fatal 'Config already exists. To create default please remove config first.'
        abort
      when SUCCESS
        logger.info 'Configure successful'
        abort
      end
    end

    # Handle codes returned from load_config
    # @param load_code [Integer] the error code returned by configure
    # @param logger [Logger] system logger
    def self.handle_load_codes(options:, load_code:, logger:)
      case load_code
      when DEPRICATED_CONFIG
        logger.warn 'Depricated config. See Above'
      when MISSING_CONFIG
        logger.fatal "Missing config file: #{options[:config]}"
        abort
      when INVALID_CONFIG
        logger.fatal 'Invalid config. See Above'
        abort
      when MISSING_MANIFEST
        logger.fatal 'Manifest file missing'
        abort
      when UNKNOWN_DEVICE
        logger.fatal "Unkown device id"
        abort
      when UNKNOWN_PROJECT
        logger.fatal "Unknown project id"
        abort
      when UNKNOWN_STAGE
        logger.fatal "Unknown stage"
        abort
      end
    end

    # Handle codes returned from checking devices
    # @param device_code [Integer] the error code returned by check_devices
    # @param logger [Logger] system logger
    def self.handle_device_codes(options:, device_code:, logger:)
      case device_code
      when CHANGED_DEVICE
        logger.info "The default device was not online so a secondary device is being used"
      when BAD_DEVICE
        logger.fatal "The selected device was not online"
        abort
      when NO_DEVICES
        logger.fatal "No configured devices were found"
        abort
      end
    end

    # Handle codes returned from handeling commands devices
    # @param device_code [Integer] the error code returned by handle_options
    # @param logger [Logger] system logger
    def self.handle_command_codes(options:, command_code:, logger:)
      case command_code
      when FAILED_SIDELOAD
        logger.fatal "Failed Sideloading App"
        abort
      when FAILED_SIGNING
        logger.fatal "Failed Signing App"
        abort
      when FAILED_DEEPLINKING
        logger.fatal "Failed Deeplinking To App"
        abort
      when FAILED_NAVIGATING
        logger.fatal "Command not sent"
        abort
      when FAILED_SCREENCAPTURE
        logger.fatal "Failed to Capture Screen"
        abort
      end
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


    # Update the intermeidate configs
    # @param configs [Hash] Intermeidate configs hash
    # @param options [Hash] Options hash
    # @return [Hash] New intermeidate configs hash
    def self.update_configs(configs:, options:)
      if options[:build_version]
        configs[:package_config][:app_name_version] = "#{configs[:project_config][:app_name]} - #{configs[:stage]} - #{options[:build_version]}" if configs[:package_config]
        unless options[:outfile]
          configs[:package_config][:out_file] = File.join(options[:out_folder], "#{configs[:project_config][:app_name]}_#{configs[:stage]}_#{options[:build_version]}.pkg") if configs[:package_config]
          configs[:build_config][:outfile] = File.join(options[:out_folder], "#{configs[:project_config][:app_name]}_#{configs[:stage]}_#{options[:build_version]}.zip") if configs[:build_config]
          configs[:inspect_config][:pkg] = configs[:package_config][:out_file] if configs[:inspect_config] and configs[:package_config]
        end
      end
      return configs
    end

    # Run a system command
    # @param command [String] The command to be run
    # @return [String] The output of the command
    def self.system(command:)
      `#{command}`.chomp
    end
  end
end
