module RokuBuilder

  MISSING_DEVICES           = 1
  MISSING_DEVICES_DEFAULT   = 2
  DEVICE_DEFAULT_BAD        = 3
  MISSING_PROJECTS          = 4
  MISSING_PROJECTS_DEFAULT  = 5
  PROJECTS_DEFAULT_BAD      = 6
  DEVICE_MISSING_IP         = 7
  DEVICE_MISSING_USER       = 8
  DEVICE_MISSING_PASSWORD   = 9
  PROJECT_MISSING_APP_NAME  = 10
  PROJECT_MISSING_DIRECTORY = 11
  PROJECT_MISSING_FOLDERS   = 12
  PROJECT_FOLDERS_BAD       = 13
  PROJECT_MISSING_FILES     = 14
  PROJECT_FILES_BAD         = 15
  STAGE_MISSING_BRANCH      = 16

  # Validate Config File
  class ConfigValidator

    # Validates the roku config
    # @param config [Hash] roku config object
    # @return [Array] error codes for valid config (see self.error_codes)
    def self.validate_config(config:, logger:)
      codes = []
      validate_structure(codes: codes, config: config)
      if config[:devices]
        config[:devices].each {|k,v|
          next if k == :default
          validate_device(codes: codes, device: v)
        }
      end
      if config[:projects]
        config[:projects].each {|project,v|
          next if project == :default
          validate_project(codes: codes, project: v)
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

    private

    def self.validate_structure(codes:, config:)
      codes.push(MISSING_DEVICES) if not config[:devices]
      codes.push(MISSING_DEVICES_DEFAULT) if config[:devices] and not config[:devices][:default]
      codes.push(DEVICE_DEFAULT_BAD) if config[:devices] and config[:devices][:default] and not config[:devices][:default].is_a?(Symbol)
      codes.push(MISSING_PROJECTS) if not config[:projects]
      codes.push(MISSING_PROJECTS_DEFAULT) if config[:projects] and not config[:projects][:default]
      codes.push(MISSING_PROJECTS_DEFAULT) if config[:projects] and config[:projects][:default] == "<project id>".to_sym
      codes.push(PROJECTS_DEFAULT_BAD) if config[:projects] and config[:projects][:default] and not config[:projects][:default].is_a?(Symbol)
    end

    def self.validate_device(codes:, device:)
      codes.push(DEVICE_MISSING_IP) if not device[:ip]
      codes.push(DEVICE_MISSING_IP) if device[:ip] == "xxx.xxx.xxx.xxx"
      codes.push(DEVICE_MISSING_IP) if device[:ip] == ""
      codes.push(DEVICE_MISSING_USER) if not device[:user]
      codes.push(DEVICE_MISSING_USER) if device[:user] == "<username>"
      codes.push(DEVICE_MISSING_USER) if device[:user] == ""
      codes.push(DEVICE_MISSING_PASSWORD) if not device[:password]
      codes.push(DEVICE_MISSING_PASSWORD) if device[:password] == "<password>"
      codes.push(DEVICE_MISSING_PASSWORD) if device[:password] == ""
    end

    def self.validate_project(codes:, project:)
      codes.push(PROJECT_MISSING_APP_NAME) if not project[:app_name]
      codes.push(PROJECT_MISSING_DIRECTORY) if not project[:directory]
      codes.push(PROJECT_MISSING_FOLDERS) if not project[:folders]
      codes.push(PROJECT_FOLDERS_BAD) if project[:folders] and not project[:folders].is_a?(Array)
      codes.push(PROJECT_MISSING_FILES) if not project[:files]
      codes.push(PROJECT_FILES_BAD) if project[:files] and not project[:files].is_a?(Array)
      project[:stages].each {|stage,value|
        codes.push(STAGE_MISSING_BRANCH) if not value[:branch]
      }
    end
  end
end
