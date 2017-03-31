# ********** Copyright Viacom, Inc. Apache 2.0 **********

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
      configs = {init_params: {}}
      #set device
      unless options[:device]
        options[:device] = config[:devices][:default]
      end
      #set project
      setup_project(config: config, options: options) if project_required(options: options)
      #set outfile
      setup_outfile(options: options, configs: configs)
      # Create Device Config
      configs[:device_config] = config[:devices][options[:device].to_sym]
      return [UNKNOWN_DEVICE, nil, nil] unless configs[:device_config]
      configs[:device_config][:logger] = logger
      project_config = setup_project_config(config: config, options: options)
      return [project_config, nil, nil] unless project_config.class == Hash
      configs[:project_config] = project_config
      stage = setup_stage_config(configs: configs, options: options, logger: logger)[1]
      return [UNKNOWN_STAGE, nil, nil] if stage.nil? and project_required(options: options)
      setup_sideload_config(configs: configs, options: options)
      code = setup_package_config(config: config, configs: configs, options: options, stage: stage)
      return [code, nil, nil] unless code == SUCCESS
      setup_active_configs(config: config, configs: configs, options: options)
      setup_manifest_configs(configs: configs, options: options)
      setup_simple_configs(config: config, configs: configs, options: options)
      return [SUCCESS, configs]
    end

    # Pick or choose the project being used
    # @param config [Hash] The loaded config hash
    # @param options [Hash] The options hash
    def self.setup_project(config:, options:)
      unless options[:project]
        path = Pathname.pwd
        project = nil
        config[:projects].each_pair {|key,value|
          if value.is_a?(Hash)
            repo_path = ""
            if config[:projects][:project_dir]
              repo_path = Pathname.new(File.join(config[:projects][:project_dir], value[:directory])).realdirpath
            else
              repo_path = Pathname.new(value[:directory]).realdirpath
            end
            path.descend do |path_parent|
              if path_parent == repo_path
                project = key
                break
              end
            end
            break if project
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
    def self.setup_outfile(options:, configs:)
      configs[:out] = {file: nil, folder: nil}
      if options[:out]
        if options[:out].end_with?(".zip") or options[:out].end_with?(".pkg") or options[:out].end_with?(".jpg")
          configs[:out][:folder], configs[:out][:file] = Pathname.new(options[:out]).split.map{|p| p.to_s}
          if configs[:out][:folder] == "." and not options[:out].start_with?(".")
            configs[:out][:folder] = nil
          else
            configs[:out][:folder] = File.expand_path(configs[:out][:folder])
          end
        else
          configs[:out][:folder] = options[:out]
        end
      end
      unless configs[:out][:folder]
         configs[:out][:folder] = "/tmp"
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
        pwd =  Pathname.pwd.to_s
        return MISSING_MANIFEST unless File.exist?(File.join(pwd, "manifest"))
        project_config = {
          directory: pwd,
          folders: nil,
          files: nil,
          stage_method: :current
        }
      elsif project_required(options: options)
        project_config = config[:projects][options[:project].to_sym]
        return UNKNOWN_PROJECT unless project_config
        if config[:projects][:project_dir]
          project_config[:directory] = File.join(config[:projects][:project_dir], project_config[:directory])
        end
        return BAD_PROJECT_DIR unless Dir.exist?(project_config[:directory])
        project_config[:stage_method] = :working if options[:working]
      end
      project_config
    end
    private_class_method :setup_project_config

    # Determine whether a project is required
    # @param options [Hash] The options hash
    # @return [Boolean] Whether a project is required or not
    def self.project_required(options:)
      has_source_command = (Controller.source_commands & options.keys).count > 0
      non_project_source = ([:current, :in] & options.keys).count > 0
      has_source_command and not non_project_source
    end
    private_class_method :project_required

    # Setup the project stage config
    # @param configs [Hash] The loaded config hash
    # @param options [Hash] The options hash
    # @return [Hash] The stage config hash
    def self.setup_stage_config(configs:, options:, logger:)
      stage_config = {logger: logger}
      stage_config[:method] = ([:in, :current] & options.keys).first
      stage = options[:stage].to_sym if options[:stage]
      if project_required(options: options)
        project_config = configs[:project_config]
        stage ||= project_config[:stages].keys[0].to_sym
        options[:stage] = stage
        stage_config[:root_dir] = project_config[:directory]
        stage_config[:method] = project_config[:stage_method]
        stage_config[:method] ||= :git
        case stage_config[:method]
        when :git
          if options[:ref]
            stage_config[:key] = options[:ref]
          else
            return [nil, nil] unless project_config[:stages][stage]
            stage_config[:key] = project_config[:stages][stage][:branch]
          end
        when :script
          return [nil, nil] unless project_config[:stages][stage]
          stage_config[:key] = project_config[:stages][stage][:script]
        end
      end
      configs[:stage_config] = stage_config
      configs[:stage] = stage
      [stage_config, stage]
    end

    # Setup config hashes for sideloading
    # @param configs [Hash] The parsed configs hash
    # @param options [Hash] The options hash
    # @param branch [String] the branch to sideload
    def self.setup_sideload_config(configs:, options:)
      root_dir, content = nil, nil
      if configs[:project_config]
        root_dir = configs[:project_config][:directory]
        content = {
          folders: configs[:project_config][:folders],
          files: configs[:project_config][:files],
        }
        all_commands = options.keys & Controller.commands
        if options[:exclude] or Controller.exclude_commands.include?(all_commands.first)
          content[:excludes] = configs[:project_config][:excludes]
        end
      end
      # Create Sideload Config
      configs[:sideload_config] = {
        update_manifest: options[:update_manifest],
        infile: options[:in],
        content: content
      }
      # Create Build Config
      configs[:build_config] = { content: content }
      configs[:init_params][:loader] = { root_dir: root_dir }
    end
    private_class_method :setup_sideload_config

    # Setup config hashes for packaging
    # @param configs [Hash] The parsed configs hash
    # @param options [Hash] The options hash
    # @param stage [Symbol] The stage to package
    def self.setup_package_config(config:, configs:, options:, stage:)
      if options[:package] or options[:key]
        # Create Key Config
        configs[:key] = configs[:project_config][:stages][stage][:key]
        if configs[:key].class == String
          configs[:key] = config[:keys][configs[:key].to_sym]
          if config[:keys][:key_dir]
            configs[:key][:keyed_pkg] = File.join(config[:keys][:key_dir], configs[:key][:keyed_pkg])
          end
          return BAD_KEY_FILE unless File.exist?(configs[:key][:keyed_pkg])
        end
      end
      if options[:package]
        # Create Package Config
        configs[:package_config] = {
          password: configs[:key][:password],
          app_name_version: "#{configs[:project_config][:app_name]} - #{stage}"
        }
        # Create Inspector Config
        configs[:inspect_config] = {
          password: configs[:key][:password]
        }
        if configs[:out][:file]
          configs[:package_config][:out_file] = File.join(configs[:out][:folder], configs[:out][:file])
          configs[:inspect_config][:pkg] = File.join(configs[:out][:folder], configs[:out][:file])
        end
      end
      return SUCCESS
    end
    private_class_method :setup_package_config

    # Setup configs for active methods, monitoring and navigating
    # @param configs [Hash] The parsed configs hash
    # @param options [Hash] The options hash
    # @param logger [Logger] System logger
    def self.setup_active_configs(config:, configs:, options:)
      # Create Monitor Config
      if options[:monitor]
        configs[:monitor_config] = {type: options[:monitor].to_sym}
        if options[:regexp]
          configs[:monitor_config][:regexp] = /#{options[:regexp]}/
        end
      end
      # Create Navigate Config
      mappings = {}
      if config[:input_mapping]
        config[:input_mapping].each_pair {|key, value|
          unless "".to_sym == key
            key = key.to_s.sub(/\\e/, "\e").to_sym
            mappings[key] = value
          end
        }
      end
      configs[:init_params][:navigator] = {mappings: mappings}
      if options[:navigate]
        commands = options[:navigate].split(/, */).map{|c| c.to_sym}
        configs[:navigate_config] = {commands: commands}
      end
    end
    private_class_method :setup_active_configs

    # Setup manifest configs
    # @param configs [Hash] The parsed configs hash
    # @param options [Hash] The options hash
    # @param logger [Logger] System logger
    def self.setup_manifest_configs(configs:, options:)
      # Create Manifest Config
      root_dir = configs[:project_config][:directory] if configs[:project_config]
      root_dir = options[:in] if options[:in]
      root_dir = Pathname.pwd.to_s if options[:current]
      configs[:manifest_config] = {
        root_dir: root_dir
      }
    end
    private_class_method :setup_manifest_configs

    # Setup other configs
    # @param configs [Hash] The parsed configs hash
    # @param options [Hash] The options hash
    # @param logger [Logger] System logger
    def self.setup_simple_configs(config:, configs:, options:)
      # Create Deeplink Config
      configs[:deeplink_config] = {options: options[:deeplink]}
      if options[:app_id]
        configs[:deeplink_config][:app_id] = options[:app_id]
      end
      # Create Text Config
      configs[:text_config] = {text: options[:text]}
      # Create Test Config
      configs[:test_config] = {sideload_config: configs[:sideload_config]}
      #Create screencapture config
      configs[:screencapture_config] = {
        out_folder: configs[:out][:folder],
        out_file: configs[:out][:file]
      }
      if options[:screen]
        configs[:screen_config] = {type: options[:screen].to_sym}
      end
      #Create Profiler Config
      if options[:profile]
        configs[:profiler_config] = {command: options[:profile].to_sym}
      end
      #Create genkey config
      configs[:genkey] = {}
      if options[:out_file]
        configs[:genkey][:out_file] = File.join(options[:out_folder], options[:out_file])
      end
    end
    private_class_method :setup_simple_configs
  end
end
