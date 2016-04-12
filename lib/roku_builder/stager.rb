module RokuBuilder

  # Change stage of roku application
  class Stager

    def initialize(key: nil, method:, root_dir:, logger:)
      @method = method
      @key = key
      @root_dir = root_dir
      @logger = logger
      @stage_success = true
      @orginal_directory = Dir.pwd
    end

    def stage
      Dir.chdir(@root_dir) unless @root_dir == @orginal_directory
      case @method
      when :current
        # Do Nothing
      when :working
        # Do Nothing
      when :git
        begin
          git_switch_to(branch: @key)
        rescue Git::GitExecuteError
          git_rescue
          @stage_success = false
        end
      when :script
        Controller.system(command: @key[:stage])
      end
      @stage_success
    end

    def unstage
      unstage_success = true
      case @method
      when :current
        # Do Nothing
      when :working
        # Do Nothing
      when :git
        begin
          git_switch_from(branch: @key, checkout: @stage_success)
        rescue Git::GitExecuteError
          git_rescue
          unstage_success = false
        end
      when :script
        Controller.system(command: @key[:unstage])
      end
      Dir.chdir(@orginal_directory) unless @root_dir == @orginal_directory
      unstage_success
    end

    private

    # Switch to the correct branch
    def git_switch_to(branch:)
      if branch
        @git ||= Git.open(@root_dir)
        if branch != @git.current_branch
          @current_branch = @git.current_branch
          @stash = @git.branch.stashes.save("roku-builder-temp-stash")
          @git.checkout(branch)
        end
      end
    end

    # Switch back to the previous branch
    def git_switch_from(branch:, checkout: true)
      if branch
        @git ||= Git.open(@root_dir)
        if @git and @current_branch
          @git.checkout(@current_branch) if checkout
          @git.branch.stashes.apply if @stash
        end
      end
    end

    # Called if resuce from git exception
    def git_rescue
      @logger.error "Branch or ref does not exist"
    end
  end
end
