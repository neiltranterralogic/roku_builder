module RokuBuilder

  # Controls all interaction with other classes
  class Controller

    ### Validation Codes ###

    # Valid Options
    VALID           = 0

    # Too many commands given
    EXTRA_COMMANDS  = 1

    # No commands given
    NO_COMMANDS     = 2

    # Too many source options given
    EXTRA_SOURCES   = 3

    # No source options given
    NO_SOURCE       = 4

    # Incorrect use of current option
    BAD_CURRENT     = 5

    # No deeplink options supplied for deeplink
    BAD_DEEPLINK    = 6

    ### Run Codes ###

    # Config has deplicated options
    DEPRICATED_CONFIG  = -1

    # Valid config
    SUCCESS            = 0

    # Tring to overwrite existing config file
    CONFIG_OVERWRITE   = 1

    # Missing config file
    MISSING_CONFIG     = 2

    # Invalid config file
    INVALID_CONFIG     = 3

    # Missing manifest file
    MISSING_MANIFEST   = 4

    # Unknow device given
    UNKNOWN_DEVICE     = 5

    # Unknown project given
    UNKNOWN_PROJECT    = 6

    # Unknown stage given
    UNKNOWN_STAGE      = 7

    # Failed to sideload app
    FAILED_SIDELOAD    = 8

    # Failed to sign app
    FAILED_SIGNING     = 9

    # Failed to deeplink to app
    FAILED_DEEPLINKING = 10

    # Failed to send navigation command
    FAILED_NAVIGATING  = 11

    # Validates the commands
    # @param options [Hash] The options hash
    # @return [Integer] Status code for command validation
    def self.validate_options(options:)
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
      if options[:deeplink]
        return BAD_DEEPLINK if !options[:deeplink_options] or options[:deeplink_options].chomp == ""
      end
      return VALID
    end

    # Run commands
    # @param options [Hash] The options hash
    # @return [Integer] Return code for options handeling
    def self.handle_options(options:)
      if options[:configure]
        return configure(options: options)
      end
      code, config, configs = self.load_config(options: options)
      command = (self.commands & options.keys).first
      case command
      when :validate
        # Do Nothing #
      when :sideload
        ### Sideload App ###
        loader = Loader.new(**configs[:device_config])
        success = loader.sideload(**configs[:sideload_config])
        return FAILED_SIGNING unless success
      when :package
        ### Package App ###
        keyer = Keyer.new(**configs[:device_config])
        loader = Loader.new(**configs[:device_config])
        packager = Packager.new(**configs[:device_config])
        inspector = Inspector.new(**configs[:device_config])
        puts "WARNING: Packaging working directory" if options[:working]
        # Sideload #
        build_version = loader.sideload(**configs[:sideload_config])
        return FAILED_SIDELOAD unless build_version
        # Key #
        success = keyer.rekey(**configs[:key])
        puts "WARNING: Key did not change" unless success
        # Package #
        options[:build_version] = build_version
        configs = self.update_configs(configs: configs, options: options)
        success = packager.package(**configs[:package_config])
        puts "Signing Successful: #{configs[:package_config][:out_file]}" if success
        return FAILED_SIGNING unless success
        # Inspect #
        if options[:inspect]
          info = inspector.inspect(configs[:inspect_config])
          puts "App Name: #{info[:app_name]}"
          puts "Dev ID: #{info[:dev_id]}"
          puts "Creation Date: #{info[:creation_date]}"
          puts "dev.zip: #{info[:dev_zip]}"
        end
      when :build
        ### Build ###
        loader = Loader.new(**device_config)
        build_version = ManifestManager.build_version(**manifest_config)
        options[:build_version] = build_version
        configs = self.update_configs(configs: configs, options: options)
        outfile = loader.build(**configs[:build_config])
        puts "Build: #{outfile}"
      when :update
        ### Update ###
        old_version = ManifestManager.build_version(**configs[:manifest_config])
        new_version = ManifestManager.update_build(**config[:manifest_config])
        puts "Update build version from:\n#{old_version}\nto:\n#{new_version}"
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
      when :text
        navigator = Navigator.new(**configs[:device_config])
        navigator.type(**configs[:text_config])
      when :test
        tester = Tester.new(**configs[:device_config])
        tester.run_tests(**configs[:test_config])
      end
      return SUCCESS
    end

    protected

    # List of command options
    # @return [Array<Symbol>] List of command symbols that can be used in the options hash
    def self.commands
      [:sideload, :package, :test, :deeplink,:configure, :validate, :delete,
        :navigate, :text, :build, :monitor, :update]
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
    def self.configure(options:)
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
        ConfigManager.edit_config(config: target_config, options: options[:edit_params], device: options[:device], project: options[:project], stage: options[:stage])
      end
      return SUCCESS
    end

    # Load config file and generate intermeidate configs
    # @param options [Hash] The options hash
    # @return [Integer] Return code
    # @return [Hash] Loaded config
    # @return [Hash] Intermeidate configs
    def self.load_config(options:)
      config_file = File.expand_path(options[:config])
      return MISSING_CONFIG unless File.exists?(config_file)
      code = SUCCESS
      config = ConfigManager.get_config(config: config_file)
      configs = {}
      codes = ConfigManager.validate_config(config: config)
      fatal = false
      warning = false
      codes.each {|code|
        if code > 0
          puts "Invalid Config: "+ ConfigManager.error_codes()[code]
          fatal = true
        elsif code < 0
          puts "Depricated Config: "+ ConfigManager.error_codes()[code]
          warning = true
        elsif code == 0 and options[:validate]
          puts "Config Valid"
        end
      }
      return [INVALID_CONFIG, nil, nil] if fatal
      code = DEPRICATED_CONFIG if warning

      #set device
      unless options[:device]
        options[:device] = config[:devices][:default]
      end
      #set project
      if options[:current] or not options[:project]
        path = `pwd`
        project = nil
        config[:projects].each_pair {|key,value|
          if value.is_a?(Hash)
            repo_path = Pathname.new(value[:directory]).realdirpath.to_s
            if path.start_with?(repo_path)
              project = key
              break
            end
          end
        }
        if project
          options[:project] = project
        else
          options[:project] = config[:projects][:default]
        end
      end
      #set outfile
      options[:out_folder] = nil
      options[:out_file] = nil
      if options[:out]
        if options[:out].end_with?(".zip") or options[:out].end_with?(".pkg")
          options[:out_folder], options[:out_file] = Pathname.new(options[:out]).split.map{|p| p.to_s}
        else
          options[:out_folder] = options[:out]
        end
      end
      unless options[:out_folder]
        options[:out_folder] = "/tmp"
      end

      # Create Device Config
      configs[:device_config] = config[:devices][options[:device].to_sym]
      return [UNKNOWN_DEVICE, nil, nil] unless configs[:device_config]
      project_config = {}
      if options[:current]
        pwd = `pwd`.chomp
        return [MISSING_MANIFEST, nil, nil] unless File.exist?(File.join(pwd, "manifest"))
        project_config = {
          directory: `pwd`.chomp,
          folders: nil,
          files: nil,
          stages: { production: { branch: nil } }
        }
      else
        project_config = config[:projects][options[:project].to_sym]
      end
      return [UNKNOWN_PROJECT, nil, nil] unless project_config
      configs[:project_config] = project_config
      stage = options[:stage].to_sym
      return [UNKNOWN_STAGE, nil, nil] unless project_config[:stages][stage]
      configs[:stage] = stage

      root_dir = project_config[:directory]
      branch = project_config[:stages][stage][:branch]
      branch = options[:ref] if options[:ref]
      branch = nil if options[:current]

      # Create Sideload Config
      configs[:sideload_config] = {
        root_dir: root_dir,
        branch: branch,
        update_manifest: options[:update_manifest],
        fetch: options[:fetch],
        folders: project_config[:folders],
        files: project_config[:files]
      }
      # Create Key Config
      configs[:key] = project_config[:stages][stage][:key]
      # Create Package Config
      configs[:package_config] = {
        password: configs[:key][:password],
        app_version_name: "#{project_config[:app_name]} - #{stage}"
      }
      if options[:outfile]
        configs[:package_config][:out_file] = File.join(options[:out_folder], options[:out_file])
      end
      # Create Inspector Config
      configs[:inspect_config] = {
        pkg: configs[:package_config][:out_file],
        password: configs[:key][:password]
      }
      # Create Build Config
      configs[:build_config] = {
        root_dir: root_dir,
        branch: branch,
        fetch: options[:fetch],
        folders: project_config[:folders],
        files: project_config[:files]
      }
      # Create Manifest Config
      configs[:manifest_config] = {
        root_dir: project_config[:directory]
      }
      # Create Deeplink Config
      configs[:deeplink_config] ={
        options: options[:deeplink_options]
      }
      # Create Monitor Config
      if options[:monitor]
        configs[:monitor_config] = {
          type: options[:monitor].to_sym
        }
      end
      # Create Navigate Config
      if options[:navigate]
        configs[:navigate_config] = {
          command: options[:navigate].to_sym
        }
      end
      # Create Text Config
      configs[:text_config] = {
        text: options[:text]
      }
      # Create Test Config
      configs[:test_config] = {
        sideload_config: configs[:sideload_config]
      }
      return [code, config, configs]
    end

    # Update the intermeidate configs
    # @param configs [Hash] Intermeidate configs hash
    # @param options [Hash] Options hash
    # @return [Hash] New intermeidate configs hash
    def self.update_configs(configs:, options:)
      if options[:build_version]
        configs[:package_config][:app_version_name] = "#{configs[:project_config][:app_name]} - #{configs[:stage]} - #{options[:build_version]}"
        unless options[:outfile]
          configs[:package_config][:out_file] = File.join(options[:out_folder], "#{configs[:project_config][:app_name]}_#{configs[:stage]}_#{options[:build_version]}.pkg")
          configs[:inspect_config][:pkg] = configs[:package_config][:out_file]
        end
      end
      return configs
    end
  end
end