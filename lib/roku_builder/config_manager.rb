module RokuBuilder
  class ConfigManager

    # Gets the roku config
    # params:
    # +config+:: path for the roku config
    # Returns:
    # +hash+:: Roku config hash
    def self.get_config(config:)
      config = JSON.parse(File.open(config).read, {symbolize_names: true})
      config[:devices][:default] = config[:devices][:default].to_sym
      config[:projects][:default] = config[:projects][:default].to_sym
      config
    end

    # validates the roku config
    # params:
    # +config+:: roku config hash
    # Returns:
    # +integer+:: error code for valid config (see self.error_codes)
    def self.validate_config(config:)
      return 1 if not config[:devices]
      return 2 if not config[:devices][:default]
      return 3 if not config[:devices][:default].is_a?(Symbol)
      return 4 if not config[:projects]
      return 5 if not config[:projects][:default]
      return 6 if not config[:projects][:default].is_a?(Symbol)
      config[:devices].each {|k,v|
        next if k = :default
        return 7 if not v[:ip]
        return 8 if not v[:user]
        return 9 if not v[:password]
      }
      config[:projects].each {|k,v|
        next if k = :default
        return 10 if not v[:app_name]
        return 11 if not v[:directory]
        return 12 if not v[:folders]
        return 13 if not v[:folders].is_a?(Array)
        return 14 if not v[:files]
        return 15 if not v[:files].is_a?(Array)
        v[:stages].each {|k,v|
          return 16 if not v[:branch]
        }
      }
    end

    # error codes for config validation
    # Returns:
    # +array+:: error code messages
    def self.error_codes()
      [
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
      ]
    end
  end
end
