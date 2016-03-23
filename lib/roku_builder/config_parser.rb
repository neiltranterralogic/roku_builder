module RokuBuilder

  # Contains methods that will parse the loaded config and generate
  # intermeidate configs for each of the tools.
  class ConfigParser

    # Parse config and generate intermeidate configs
    # @param options [Hash] The options hash
    # @param config [Hash] The loaded config hash
    # @param logger [Logger] system logger
    # @return [Integer] Return code
    # @return [Hash] Intermeidate configs
    def self.parse_config(options:, config:, logger:)
      configs = {}
      #set device
      unless options[:device]
        options[:device] = config[:devices][:default]
      end
      #set project
      setup_project(config: config, options: options)
      #set outfile
      setup_outfile(options: options)
      # Create Device Config
      configs[:device_config] = config[:devices][options[:device].to_sym]
      return [UNKNOWN_DEVICE, nil, nil] unless configs[:device_config]
      configs[:device_config][:logger] = logger
      project_config = setup_project_config(config: config, options: options)
      return [UNKNOWN_PROJECT, nil, nil] unless project_config
      configs[:project_config] = project_config
      stage = options[:stage].to_sym
      return [UNKNOWN_STAGE, nil, nil] unless project_config[:stages][stage]
      configs[:stage] = stage
      branch = project_config[:stages][stage][:branch]
      branch = options[:ref] if options[:ref]
      branch = nil if options[:current]
      branch = nil if options[:working]
      setup_sideload_config(configs: configs, options: options, branch: branch)
      setup_package_config(configs: configs, options: options, stage: stage)
      setup_simple_configs(configs: configs, options: options, logger: logger)
      return [SUCCESS, configs]
    end

    # Pick or choose the project being used
    # @param config [Hash] The loaded config hash
    # @param options [Hash] The options hash
    def self.setup_project(config:, options:)
      if options[:current] or not options[:project]
        path = Controller.system(command: "pwd")
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
    end
    private_class_method :setup_project

    # Setup the out folder/file options
    # @param options [Hash] The options hash
    def self.setup_outfile(options:)
      options[:out_folder] = nil
      options[:out_file] = nil
      if options[:out]
        if options[:out].end_with?(".zip") or options[:out].end_with?(".pkg") or options[:out].end_with?(".jpg")
          options[:out_folder], options[:out_file] = Pathname.new(options[:out]).split.map{|p| p.to_s}
        else
          options[:out_folder] = options[:out]
        end
      end
      unless options[:out_folder]
        options[:out_folder] = "/tmp"
      end
    end
    private_class_method :setup_outfile

    # Setup the project config with the chosen project
    # @param config [Hash] The loaded config hash
    # @param options [Hash] The options hash
    # @return [Hash] The project config hash
    def self.setup_project_config(config:, options:)
      #Create Project Config
      project_config = {}
      if options[:current]
        pwd =  Controller.system(command: "pwd")
        return [MISSING_MANIFEST, nil, nil] unless File.exist?(File.join(pwd, "manifest"))
        project_config = {
          directory: pwd,
          folders: nil,
          files: nil,
          stages: { production: { branch: nil } }
        }
      else
        project_config = config[:projects][options[:project].to_sym]
      end
      project_config
    end
    private_class_method :setup_project_config

    # Setup config hashes for sideloading
    # @param configs [Hash] The parsed configs hash
    # @param options [Hash] The options hash
    # @param branch [String] the branch to sideload
    def self.setup_sideload_config(configs:, options:, branch:)
      root_dir = configs[:project_config][:directory]
      # Create Sideload Config
      configs[:sideload_config] = {
        root_dir: root_dir,
        branch: branch,
        update_manifest: options[:update_manifest],
        folders: configs[:project_config][:folders],
        files: configs[:project_config][:files]
      }
      # Create Build Config
      configs[:build_config] = {
        root_dir: root_dir,
        branch: branch,
        folders: configs[:project_config][:folders],
        files: configs[:project_config][:files]
      }
    end
    private_class_method :setup_sideload_config

    # Setup config hashes for packaging
    # @param configs [Hash] The parsed configs hash
    # @param options [Hash] The options hash
    # @param stage [Symbol] The stage to package
    def self.setup_package_config(configs:, options:, stage:)
      if options[:package]
        # Create Key Config
        configs[:key] = configs[:project_config][:stages][stage][:key]
        # Create Package Config
        configs[:package_config] = {
          password: configs[:key][:password],
          app_name_version: "#{configs[:project_config][:app_name]} - #{stage}"
        }
        if options[:out_file]
          configs[:package_config][:out_file] = File.join(options[:out_folder], options[:out_file])
        end
        # Create Inspector Config
        configs[:inspect_config] = {
          pkg: configs[:package_config][:out_file],
          password: configs[:key][:password]
        }
      end
    end
    private_class_method :setup_package_config

    # Setup other configs
    # @param configs [Hash] The parsed configs hash
    # @param options [Hash] The options hash
    # @param logger [Logger] System logger
    def self.setup_simple_configs(configs:, options:, logger:)
      # Create Manifest Config
      configs[:manifest_config] = {
        root_dir: configs[:project_config][:directory]
      }
      # Create Deeplink Config
      configs[:deeplink_config] ={options: options[:deeplink_options]}
      # Create Monitor Config
      if options[:monitor]
        configs[:monitor_config] = {type: options[:monitor].to_sym}
      end
      # Create Navigate Config
      if options[:navigate]
        configs[:navigate_config] = {command: options[:navigate].to_sym}
      end
      # Create Text Config
      configs[:text_config] = {text: options[:text]}
      # Create Test Config
      configs[:test_config] = {sideload_config: configs[:sideload_config]}
      #Create screencapture config
      configs[:screencapture_config] = {
        out_folder: options[:out_folder],
        out_file: options[:out_file]
      }
      if options[:screen]
        configs[:screen_config] = {type: options[:screen].to_sym}
      end
    end
    private_class_method :setup_simple_configs
  end
end
