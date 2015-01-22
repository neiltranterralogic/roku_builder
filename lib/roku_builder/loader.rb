module RokuBuilder
  class Loader < Util

    # Sideload an app onto a roku device
    # Params:
    #  +root_dir+:: root directory of the roku app
    #  +branch+:: branch of the git repository to sideload
    #  Returns:
    #  +string+:: build version or 'intermediate' on success, nil otherwise
    def sideload(root_dir:, branch:, update_manifest:)
      @root_dir = root_dir
      result = nil
      stash = nil
      git = Git.open(@root_dir)
      current_dir = Dir.pwd
      begin
        if branch
          Dir.chdir(@root_dir)
          current_branch = git.current_branch
          stash = git.branch.stashes.save("roku-builder-temp-stash")
          git.checkout(branch)
        end

        # Update manifest
        build_version = "intermediate"
        if update_manifest
          build_version = ManifestManager.update_build(root_dir: root_dir)
        end

        folders = ['resources', 'source']
        files = ['manifest']
        file = Tempfile.new('pkg')
        outfile = "#{file.path}.zip"
        file.unlink

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

        if current_branch
          git.checkout(current_branch)
          git.branch.stashes.apply if stash
        end

        if response.status == 200 and response.body =~ /Install Success/
          result = build_version
        end

      rescue Git::GitExecuteError => e
        puts "FATAL: Branch or ref does not exist"
        puts e.message
        puts e.backtrace
      ensure
        Dir.chdir(current_dir) unless current_dir == Dir.pwd
      end
      result
    end

    private

    # Recursively write folders to a zip archive
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
