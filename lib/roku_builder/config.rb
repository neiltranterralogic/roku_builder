# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder

  # Load and validate config files.
  class Config

    attr_reader :parsed

    def initialize(options:)
      @options = options
      @logger = Logger.instance
      @config = nil
      @parsed = nil
      check_config_file
      load_config
      fix_config_symbol_values
      validate_config
    end

    def raw
      @config
    end

    def parse
      @parsed = ConfigParser.parse(options: @options, config: @config)
    end

    private

    def check_config_file
      config_file = File.expand_path(@options[:config])
      raise ArgumentError, "Missing Config" unless File.exist?(config_file)
    end

    def validate_config
      validator = ConfigValidator.new(config: @config)
      validator.print_errors
      raise InvalidConfig if validator.is_fatal?
    end

    def load_config
      @config = {parent_config: @options[:config]}
      depth = 1
      while @config[:parent_config]
        parent_config_hash = get_parent_config
        @config[:child_config] = @config[:parent_config]
        @config.delete(:parent_config)
        @config.merge!(parent_config_hash) {|_key, v1, _v2| v1}
        depth += 1
        raise InvalidConfig, "Parent Configs Too Deep." if depth > 10
      end
    end

    def get_parent_config
      begin
        JSON.parse(parent_io.read, {symbolize_names: true})
      rescue JSON::ParserError
        raise InvalidConfig, "Config file is not valid JSON"
      end
    end

    def parent_io
      expand_parent_file_path
      File.open(@config[:parent_config])
    end

    def expand_parent_file_path
      if @config[:child_config]
        @config[:parent_config] = File.expand_path(@config[:parent_config], File.dirname(@config[:child_config]))
      end
    end

    def fix_config_symbol_values
      if @config[:devices]
        @config[:devices][:default] = @config[:devices][:default].to_sym
      end
      if @config[:projects]
        fix_project_config_symbol_values
        build_inhearited_project_configs
      end
    end

    def fix_project_config_symbol_values
      @config[:projects][:default] = @config[:projects][:default].to_sym
      @config[:projects].each_pair do |key,value|
        next if is_skippable_project_key? key
        if value[:stage_method]
          value[:stage_method] = value[:stage_method].to_sym
        end
      end
    end

    def build_inhearited_project_configs
      @config[:projects].each_pair do |key,value|
        next if is_skippable_project_key? key
        if value[:parent] and config[:projects][value[:parent].to_sym]
          new_value = config[:projects][value[:parent].to_sym]
          new_value = new_value.deep_merge value
          config[:projects][key] = new_value
        end
      end
    end

    def is_skippable_project_key?(key)
      [:project_dir, :default].include?(key)
    end


    def edit_config
      apply_options(state: state)
      config_string = JSON.pretty_generate(config_object)
      file = File.open(config, "w")
      file.write(config_string)
      file.close
      return true
    end

    def build_edit_state
      {
        project: get_project_key,
        device: get_device_key,
        stage: get_stage_key(project: get_project_key)
      }
    end

    def get_project_key
      project = @options[:project].to_sym if @options[:project]
      project ||= @config[:projects][:default]
      project
    end
    def get_device_key
      device = @options[:device].to_sym if @options[:device]
      device ||= @config[:devices][:default]
      device
    end
    def get_stage_key(project:)
      stage = @options[:stage].to_sym if @options[:stage]
      stage ||= @config_object[:projects][project][:stages].keys[0].to_sym
      stage
    end

    # Apply the changes in the options string to the config object
    # @param config_object [Hash] The config loaded from file
    # @param options [String] The string of options passed in by the user
    # @param state [Hash] The state of the config the user is editing
    def self.apply_options(state:)
      changes = Util.options_parse(options: @options[:edit_params])
      changes.each {|key,value|
        if [:ip, :user, :password].include?(key)
          @config_object[:devices][state[:device]][key] = value
        elsif [:directory, :app_name].include?(key) #:folders, :files
          @config_object[:projects][state[:project]][key] = value
        elsif [:branch].include?(key)
          @config_object[:projects][state[:project]][:stages][state[:stage]][key] = value
        end
      }
    end
    private_class_method :apply_options

    # Update the intermeidate configs
    # @param configs [Hash] Intermeidate configs hash
    # @param options [Hash] Options hash
    # @return [Hash] New intermeidate configs hash
    def self.update_configs(configs:, options:)
      if options[:build_version]
        configs[:package_config][:app_name_version] = "#{configs[:project_config][:app_name]} - #{configs[:stage]} - #{options[:build_version]}" if configs[:package_config]
        unless configs[:out][:file]
          configs[:out][:file] = "#{configs[:project_config][:app_name]}_#{configs[:stage]}_#{options[:build_version]}"
        end
        pathname = File.join(configs[:out][:folder], configs[:out][:file])
        configs[:package_config][:out_file] = pathname if configs[:package_config]
        configs[:build_config][:out_file]   = pathname if configs[:build_config]
        if configs[:sideload_config] and options[:out]
          configs[:sideload_config][:out_file]   = pathname
        end
        configs[:inspect_config][:pkg] = configs[:package_config][:out_file] if configs[:inspect_config] and configs[:package_config]
      end
      return configs
    end
  end
end
