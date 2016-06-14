# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder

  # Helper for extending for scripting
  class Scripter

    # Prints attributes from config or project to allow scripting
    # @param attribute [Symbol] attribute to print
    # @param configs [Hash] Parsed config hash
    def self.print(attribute:, configs:)
      attributes = [
        :title, :build_version, :app_version, :root_dir
      ]

      unless attributes.include? attribute
        return BAD_PRINT_ATTRIBUTE
      end

      read_config = {root_dir: configs[:project_config][:directory]}

      case attribute
      when :root_dir
        printf "%s", configs[:project_config][:directory]
      when :title
        printf "%s", ManifestManager.read_manifest(**read_config)[:title]
      when :build_version
        printf "%s", ManifestManager.read_manifest(**read_config)[:build_version]
      when :app_version
        major = ManifestManager.read_manifest(**read_config)[:major_version]
        minor = ManifestManager.read_manifest(**read_config)[:minor_version]
        printf "%s.%s", major, minor
      end
      SUCCESS
    end
  end
end
