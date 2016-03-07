module RokuBuilder

  # Load/Unload/Build roku applications
  class Loader < Util

    # Sideload an app onto a roku device
    # @param root_dir [String] Path to the root directory of the roku app
    # @param branch [String] Branch of the git repository to sideload. Pass nil to use working directory. Default: nil
    # @param update_manifest [Boolean] Flag to update the manifest file before sideloading. Default: false
    # @param fetch [Boolean] Flag to fetch all remotes before sideloading. Default: false
    # @param folders [Array<String>] Array of folders to be sideloaded. Pass nil to send all folders. Default: nil
    # @param files [Array<String>] Array of files to be sideloaded. Pass nil to send all files. Default: nil
    # @param infile [String] 
    # @return [String] Build version on success, nil otherwise
    def sideload(root_dir:, branch: nil, update_manifest: false, fetch: false, folders: nil, files: nil, infile: nil)
      @root_dir = root_dir
      result = nil
      stash = nil
      if branch
        git = Git.open(@root_dir)
        if fetch
          for remote in git.remotes
            git.fetch(remote)
          end
        end
      end
      current_dir = Dir.pwd
      begin
        if git and branch and branch != git.current_branch
          Dir.chdir(@root_dir)
          current_branch = git.current_branch
          stash = git.branch.stashes.save("roku-builder-temp-stash")
          git.checkout(branch)
        end

        # Update manifest
        build_version = ""
        if update_manifest
          build_version = ManifestManager.update_build(root_dir: root_dir, logger: @logger)
        else
          build_version = ManifestManager.build_version(root_dir: root_dir, logger: @logger)
        end

        outfile = build(root_dir: root_dir, branch: branch, build_version: build_version, folders: folders, files: files)

        path = "/plugin_install"

        # Connect to roku and upload file
        conn = Faraday.new(url: @url) do |f|
          f.request :digest, @dev_username, @dev_password
          f.request :multipart
          f.request :url_encoded
          f.adapter Faraday.default_adapter
        end
        payload =  {
          mysubmit: "Replace",
          archive: Faraday::UploadIO.new(outfile, 'application/zip')
        }
        response = conn.post path, payload

        # Cleanup
        File.delete(outfile)

        if git and current_branch
          git.checkout(current_branch)
          git.branch.stashes.apply if stash
        end

        if response.status == 200 and response.body =~ /Install Success/
          result = build_version
        end

      rescue Git::GitExecuteError => e
        @logger.error "Branch or ref does not exist"
        @logger.error e.message
        @logger.error e.backtrace
      ensure
        Dir.chdir(current_dir) unless current_dir == Dir.pwd
      end
      result
    end


    # Build an app to sideload later
    # @param root_dir [String] Path to the root directory of the roku app
    # @param branch [String] Branch of the git repository to sideload. Pass nil to use working directory. Default: nil
    # @param build_version [String] Version to assigne to the build. If nil will pull the build version form the manifest. Default: nil
    # @param outfile [String] Path for the output file. If nil will create a file in /tmp. Default: nil
    # @param fetch [Boolean] Flag to fetch all remotes before sideloading. Default: false
    # @param folders [Array<String>] Array of folders to be sideloaded. Pass nil to send all folders. Default: nil
    # @param files [Array<String>] Array of files to be sideloaded. Pass nil to send all files. Default: nil
    # @return [String] Path of the build
    def build(root_dir:, branch: nil, build_version: nil, outfile: nil, fetch: false, folders: nil, files: nil)
      @root_dir = root_dir
      result = nil
      stash = nil
      if branch
        git = Git.open(@root_dir)
        if fetch
          for remote in git.remotes
            git.fetch(remote)
          end
        end
      end
      current_dir = Dir.pwd
      begin
        if git and branch and branch != git.current_branch
          Dir.chdir(@root_dir)
          current_branch = git.current_branch
          stash = git.branch.stashes.save("roku-builder-temp-stash")
          git.checkout(branch)
        end

        build_version = ManifestManager.build_version(root_dir: root_dir, logger: @logger) unless build_version
        unless folders
          folders = Dir.entries(root_dir).select {|entry| File.directory? File.join(root_dir, entry) and !(entry =='.' || entry == '..') }
        end
        unless files
          files = Dir.entries(root_dir).select {|entry| File.file? File.join(root_dir, entry)}
        end
        outfile = "/tmp/build_#{build_version}.zip" unless outfile

        File.delete(outfile) if File.exists?(outfile)
        io = Zip::File.open(outfile, Zip::File::CREATE)

        # Add folders to zip
        folders.each do |folder|
          base_folder = File.join(@root_dir, folder)
          entries = Dir.entries(base_folder)
          entries.delete(".")
          entries.delete("..")
          writeEntries(@root_dir, entries, folder, io)
        end

        # Add file to zip
        writeEntries(@root_dir, files, "", io)

        io.close()

        if git and current_branch
          git.checkout(current_branch)
          git.branch.stashes.apply if stash
        end
      rescue Git::GitExecuteError => e
        @logger.error "Branch or ref does not exist"
        @logger.error e.message
        @logger.error e.backtrace
      ensure
        Dir.chdir(current_dir) unless current_dir == Dir.pwd
      end
      outfile
    end

    # Remove the currently sideloaded app
    def unload()
        path = "/plugin_install"

        # Connect to roku and upload file
        conn = Faraday.new(url: @url) do |f|
          f.headers['Content-Type'] = Faraday::Request::Multipart.mime_type
          f.request :digest, @dev_username, @dev_password
          f.request :multipart
          f.request :url_encoded
          f.adapter Faraday.default_adapter
        end
        payload =  {
          mysubmit: "Delete",
          archive: ""
        }
        response = conn.post path, payload
        if response.status == 200 and response.body =~ /Install Success/
          return true
        end
        return false
    end

    private

    # Recursively write directory contents to a zip archive
    # @param root_dir [String] Path of the root directory
    # @param entries [Array<String>] Array of file paths of files/directories to store in the zip archive
    # @param path [String] The path of the current directory starting at the root directory
    # @param io [IO] zip IO object
    def writeEntries(root_dir, entries, path, io)
      entries.each { |e|
        zipFilePath = path == "" ? e : File.join(path, e)
        diskFilePath = File.join(root_dir, zipFilePath)
        if File.directory?(diskFilePath)
          io.mkdir(zipFilePath)
          subdir =Dir.entries(diskFilePath); subdir.delete("."); subdir.delete("..")
          writeEntries(root_dir, subdir, zipFilePath, io)
        else
          io.get_output_stream(zipFilePath) { |f| f.puts(File.open(diskFilePath, "rb").read()) }
        end
      }
    end
  end
end
