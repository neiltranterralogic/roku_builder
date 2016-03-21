module RokuBuilder

  # Commands that the controller uses to interface with the rest of the gem.
  class ControllerCommands
    # Validate Config
    # @return [Integer] Success or Failure Code
    def self.validate()
      SUCCESS
    end
    # Run Sideload
    # @param configs [Hash] parsed configs
    # @return [Integer] Success or Failure Code
    def self.sideload(configs:)
      args = { klass: Loader, method: :sideload, config_key: :sideload_config,
        configs: configs, failure: FAILED_SIDELOAD }
      simple_command(**args)
    end
    # Run Package
    # @param options [Hash] user options
    # @param configs [Hash] parsed configs
    # @param logger [Logger] system logger
    # @return [Integer] Success or Failure Code
    def self.package(options:, configs:, logger:)
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
      configs = ConfigManager.update_configs(configs: configs, options: options)
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
      SUCCESS
    end
    # Run Build
    # @param options [Hash] user options
    # @param config [Hash] loaded config object
    # @param configs [Hash] parsed configs
    # @param logger [Logger] system logger
    # @return [Integer] Success or Failure Code
    def self.build(options:, configs:, logger:)
      ### Build ###
      loader = Loader.new(**configs[:device_config])
      build_version = ManifestManager.build_version(**configs[:manifest_config])
      options[:build_version] = build_version
      configs = ConfigManager.update_configs(configs: configs, options: options)
      outfile = loader.build(**configs[:build_config])
      logger.info "Build: #{outfile}"
      SUCCESS
    end
    # Run update
    # @param configs [Hash] parsed configs
    # @param logger [Logger] system logger
    # @return [Integer] Success or Failure Code
    def self.update(configs:, logger:)
      ### Update ###
      old_version = ManifestManager.build_version(**configs[:manifest_config])
      new_version = ManifestManager.update_build(**configs[:manifest_config])
      logger.info "Update build version from:\n#{old_version}\nto:\n#{new_version}"
      SUCCESS
    end
    # Run deeplink
    # @param configs [Hash] parsed configs
    # @return [Integer] Success or Failure Code
    def self.deeplink(configs:)
      ### Deeplink ###
      args = { klass: Linker, method: :link, config_key: :deeplink_config,
        configs: configs, failure: FAILED_DEEPLINKING }
      simple_command(**args)
    end
    # Run delete
    # @param configs [Hash] parsed configs
    # @return [Integer] Success or Failure Code
    def self.delete(configs:)
      args = { klass: Loader, method: :unload, configs: configs }
      simple_command(**args)
    end
    # Run Monitor
    # @param configs [Hash] parsed configs
    # @return [Integer] Success or Failure Code
    def self.monitor(configs:)
      args = { klass: Monitor, method: :monitor,
        config_key: :monitor_config, configs: configs }
      simple_command(**args)
    end
    # Run navigate
    # @param configs [Hash] parsed configs
    # @return [Integer] Success or Failure Code
    def self.navigate(configs:)
      args = { klass: Navigator, method: :nav, config_key: :navigate_config,
        configs: configs, failure: FAILED_NAVIGATING }
      simple_command(**args)
    end
    # Run screen
    # @param configs [Hash] parsed configs
    # @return [Integer] Success or Failure Code
    def self.screen(configs:)
      args = { klass: Navigator, method: :screen, config_key: :screen_config,
        configs: configs, failure: FAILED_NAVIGATING }
      simple_command(**args)
    end
    # Run screens
    # @param configs [Hash] parsed configs
    # @return [Integer] Success or Failure Code
    def self.screens(configs:)
      args = { klass: Navigator, method: :screens, configs: configs  }
      simple_command(**args)
    end
    # Run text
    # @param configs [Hash] parsed configs
    # @return [Integer] Success or Failure Code
    def self.text(configs:)
      args = { klass: Navigator, method: :type, config_key: :text_config,
        configs: configs  }
      simple_command(**args)
    end
    # Run test
    # @param configs [Hash] parsed configs
    # @return [Integer] Success or Failure Code
    def self.test(configs:)
      args = { klass: Tester, method: :run_tests, config_key: :test_config,
        configs: configs  }
      simple_command(**args)
    end
    # Run Screencapture
    # @param configs [Hash] parsed configs
    # @return [Integer] Success or Failure Code
    def self.screencapture(configs:)
      args = { klass: Inspector, method: :screencapture, config_key: :screencapture_config,
        configs: configs, failure: FAILED_SCREENCAPTURE }
      simple_command(**args)
    end

    private

    def self.simple_command(klass:, method:, config_key: nil, configs:, failure: nil)
      instance = klass.new(**configs[:device_config])
      if config_key
        success = instance.send(method, configs[config_key])
      else
        success = instance.send(method)
      end
      return failure unless failure.nil? or success
      SUCCESS
    end
  end
end
