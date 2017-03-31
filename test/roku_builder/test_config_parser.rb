# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

class ConfigParserTest < Minitest::Test
  def test_manifest_config
    logger = Logger.new("/dev/null")
    options = {
      config: File.expand_path(File.join(File.dirname(__FILE__), "test_files", "controller_config_test", "valid_config.json")),
      stage: 'production',
      update_manifest: false,
      fetch: false,
      sideload: true
    }
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)

    assert_equal RokuBuilder::SUCCESS, code
    assert_equal Hash, config.class
    assert_equal "/tmp", configs[:manifest_config][:root_dir]
  end

  def test_manifest_config_in
    logger = Logger.new("/dev/null")
    options = {
      config: File.expand_path(File.join(File.dirname(__FILE__), "test_files", "controller_config_test", "valid_config.json")),
      in: "/dev/null/infile",
      update_manifest: false,
      fetch: false,
      sideload: true
    }
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)

    assert_equal RokuBuilder::SUCCESS, code
    assert_equal Hash, config.class
    assert_equal "/dev/null/infile", configs[:manifest_config][:root_dir]
    assert_equal :in, configs[:stage_config][:method]
  end

  def test_manifest_config_in_expand
    logger = Logger.new("/dev/null")
    options = {
      config: File.expand_path(File.join(File.dirname(__FILE__), "test_files", "controller_config_test", "valid_config.json")),
      in: "./infile",
      update_manifest: false,
      fetch: false,
      sideload: true
    }
    config = good_config
    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)

    assert_equal RokuBuilder::SUCCESS, code
    assert_equal Hash, config.class
    assert_equal File.join(Dir.pwd, "infile"), configs[:manifest_config][:root_dir]
    assert_equal :in, configs[:stage_config][:method]
  end

  def test_manifest_config_current
    logger = Logger.new("/dev/null")
    options = {
      config: File.expand_path(File.join(File.dirname(__FILE__), "test_files", "controller_config_test", "valid_config.json")),
      current: true,
      update_manifest: false,
      fetch: false,
      sideload: true
    }
    code, configs = nil
    config = good_config
    Pathname.stub(:pwd, "/dev/null/infile") do
      File.stub(:exist?, true) do
        code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
      end
    end

    assert_equal RokuBuilder::SUCCESS, code
    assert_equal Hash, config.class
    assert_equal "/dev/null/infile", configs[:manifest_config][:root_dir]
    assert_equal :current, configs[:stage_config][:method]
  end

  def test_setup_project_config_current
    args = {
      config: {},
      options: {current: true }
    }
    project = {}
    File.stub(:exist?, true) do
      project = RokuBuilder::ConfigParser.send(:setup_project_config, **args)
    end
    assert_equal Pathname.pwd.to_s, project[:directory]
    assert_equal :current, project[:stage_method]
    assert_nil project[:folders]
    assert_nil project[:files]
  end

  def test_setup_project_config_good_project_dir
    config = good_config
    args = {
      config: config,
      options: {sideload: true, project: :project1}
    }
    project = {}
    File.stub(:exist?, true) do
      project = RokuBuilder::ConfigParser.send(:setup_project_config, **args)
    end
    refute_equal RokuBuilder::BAD_PROJECT_DIR, project
  end

  def test_setup_project_config_bad_project_dir
    config = good_config
    config[:projects][:project1][:directory] = "/dev/null"
    args = {
      config: config,
      options: {sideload: true, project: :project1}
    }
    project = {}
    File.stub(:exist?, true) do
      project = RokuBuilder::ConfigParser.send(:setup_project_config, **args)
    end
    assert_equal RokuBuilder::BAD_PROJECT_DIR, project
  end

  def test_setup_project_config_bad_child_project_dir
    config = good_config
    config[:projects][:project_dir] = "/tmp"
    config[:projects][:project1][:directory] = "bad"
    args = {
      config: config,
      options: {sideload: true, project: :project1}
    }
    project = {}
    File.stub(:exist?, true) do
      project = RokuBuilder::ConfigParser.send(:setup_project_config, **args)
    end
    assert_equal RokuBuilder::BAD_PROJECT_DIR, project
  end

  def test_setup_project_config_bad_parent_project_dir
    config = good_config
    config[:projects][:project_dir] = "/bad"
    config[:projects][:project1][:directory] = "good"
    args = {
      config: config,
      options: {sideload: true, project: :project1}
    }
    project = {}
    File.stub(:exist?, true) do
      project = RokuBuilder::ConfigParser.send(:setup_project_config, **args)
    end
    assert_equal RokuBuilder::BAD_PROJECT_DIR, project
  end

  def test_setup_stage_config_script
    args = {
      configs: {project_config: {directory: "/tmp", stage_method: :script, stages: {production: {script: "script"}}}},
      options: {stage: "production", sideload: true},
      logger: Logger.new("/dev/null")
    }
    config = RokuBuilder::ConfigParser.send(:setup_stage_config, **args)[0]
    assert_equal args[:configs][:project_config][:stages][:production][:script], config[:key]
  end

  def test_setup_stage_config_git_ref
    args = {
      configs: {project_config: {directory: "/tmp", stage_method: :git, }},
      options: {stage: "production", ref: "git-ref", sideload: true},
      logger: Logger.new("/dev/null")
    }
    config = RokuBuilder::ConfigParser.send(:setup_stage_config, **args)[0]
    assert_equal args[:options][:ref], config[:key]
  end

  def test_manifest_config_project_select
    logger = Logger.new("/dev/null")
    options = {
      config: File.expand_path(File.join(File.dirname(__FILE__), "test_files", "controller_config_test", "valid_config.json")),
      stage: 'production',
      update_manifest: false,
      fetch: false,
      sideload: true
    }
    config = good_config

    code = nil
    configs = nil

    Pathname.stub(:pwd, Pathname.new("/dev/nuller")) do
      code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    end

    assert_equal RokuBuilder::SUCCESS, code
    assert_equal Hash, config.class
    assert_equal "/tmp", configs[:project_config][:directory]
  end

  def test_manifest_config_project_directory
    logger = Logger.new("/dev/null")
    options = {
      sideload: true
    }
    config = good_config
    config[:projects][:project_dir] = "/tmp"
    config[:projects][:project1][:directory] = "project1"
    config[:projects][:project2][:directory] = "project2"


    code = nil
    configs = nil

    Dir.stub(:exist?, true) do
      code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
    end

    assert_equal RokuBuilder::SUCCESS, code
    assert_equal Hash, config.class
    assert_equal "/tmp/project1", configs[:project_config][:directory]
  end

  def test_manifest_config_project_directory_select
    logger = Logger.new("/dev/null")
    options = {
      config: File.expand_path(File.join(File.dirname(__FILE__), "test_files", "controller_config_test", "valid_config.json")),
      stage: 'production',
      update_manifest: false,
      fetch: false,
      sideload: true
    }
    config = good_config
    config[:projects][:project_dir] = "/tmp"
    config[:projects][:project1][:directory] = "project1"
    config[:projects][:project2][:directory] = "project2"

    code = nil
    configs = nil

    Pathname.stub(:pwd, Pathname.new("/tmp/project2")) do
      Dir.stub(:exist?, true) do
        code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)
      end
    end

    assert_equal RokuBuilder::SUCCESS, code
    assert_equal Hash, config.class
    assert_equal "/tmp/project2", configs[:project_config][:directory]
  end

  def test_manifest_config_key_directory
    tmp_file = Tempfile.new("pkg")
    logger = Logger.new("/dev/null")
    options = {key: true, project: :project2}
    config = good_config
    config[:keys][:key_dir] = File.dirname(tmp_file.path)
    config[:keys][:a][:keyed_pkg] = File.basename(tmp_file.path)


    code = nil
    configs = nil

    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)

    assert_equal RokuBuilder::SUCCESS, code
    assert_equal Hash, config.class
    assert_equal tmp_file.path, configs[:key][:keyed_pkg]
    tmp_file.close
  end

  def test_manifest_config_key_directory_bad
    tmp_file = Tempfile.new("pkg")
    logger = Logger.new("/dev/null")
    options = {key: true, project: :project2}
    config = good_config
    config[:keys][:key_dir] = "/bad"
    config[:keys][:a][:keyed_pkg] = File.basename(tmp_file.path)

    code = nil
    configs = nil

    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)

    assert_equal RokuBuilder::BAD_KEY_FILE, code
  end

  def test_manifest_config_key_path_bad
    tmp_file = Tempfile.new("pkg")
    logger = Logger.new("/dev/null")
    options = {key: true, project: :project2}
    config = good_config
    config[:keys][:key_dir] = File.dirname(tmp_file.path)
    config[:keys][:a][:keyed_pkg] = File.basename(tmp_file.path)+".bad"

    code = nil
    configs = nil

    code, configs = RokuBuilder::ConfigParser.parse_config(options: options, config: config, logger: logger)

    assert_equal RokuBuilder::BAD_KEY_FILE, code
  end

  def test_setup_sideload_config
    args = {
      configs: {project_config: {directory: "/tmp", folders: ["a", "b"], files: ["c", "d"], excludes: []}, init_params: {}},
      options: {sideload: true}
    }
    RokuBuilder::ConfigParser.send(:setup_sideload_config, **args)

    refute_nil args[:configs][:sideload_config]
    refute_nil args[:configs][:sideload_config][:content]
    refute_nil args[:configs][:build_config]
    refute_nil args[:configs][:build_config][:content]
    refute_nil args[:configs][:init_params][:loader]
    refute_nil args[:configs][:init_params][:loader][:root_dir]

    assert_nil args[:configs][:sideload_config][:content][:excludes]
    assert_nil args[:configs][:sideload_config][:update_manifest]
    assert_nil args[:configs][:sideload_config][:infile]
  end
  def test_setup_sideload_config_exclude
    args = {
      configs: {project_config: {directory: "/tmp", folders: ["a", "b"], files: ["c", "d"], excludes: []}, init_params: {}},
      options: {sideload: true}
    }
    RokuBuilder::ConfigParser.send(:setup_sideload_config, **args)
    assert_nil args[:configs][:sideload_config][:content][:excludes]

    args = {
      configs: {project_config: {directory: "/tmp", folders: ["a", "b"], files: ["c", "d"], excludes: []}, init_params: {}},
      options: {build: true}
    }
    RokuBuilder::ConfigParser.send(:setup_sideload_config, **args)
    refute_nil args[:configs][:sideload_config][:content][:excludes]

    args = {
      configs: {project_config: {directory: "/tmp", folders: ["a", "b"], files: ["c", "d"], excludes: []}, init_params: {}},
      options: {package: true}
    }
    RokuBuilder::ConfigParser.send(:setup_sideload_config, **args)
    refute_nil args[:configs][:sideload_config][:content][:excludes]

    args = {
      configs: {project_config: {directory: "/tmp", folders: ["a", "b"], files: ["c", "d"], excludes: []}, init_params: {}},
      options: {sideload: true, exclude: true}
    }
    RokuBuilder::ConfigParser.send(:setup_sideload_config, **args)
    refute_nil args[:configs][:sideload_config][:content][:excludes]
  end

  def test_deeplink_app_config
    args = {
      config: {},
      configs: {project_config: {directory: "dir"}, init_params: {}, out: {}},
      options: {deeplink: "a:b", app_id: "xxxxxx"},
    }
    RokuBuilder::ConfigParser.send(:setup_simple_configs, **args)
  end

  def test_monitor_config
    args = {
      config: {},
      configs: {project_config: {directory: "dir"}, init_params: {}, out: {}},
      options: {monitor: "main", regexp: "^A$"},
    }
    RokuBuilder::ConfigParser.send(:setup_active_configs, **args)
    refute_nil args[:configs][:monitor_config][:regexp]
    assert args[:configs][:monitor_config][:regexp].match("A")
  end

  def test_outfile_config
    configs = {}
    args = {
     options: {out: nil},
     configs: configs
    }
    RokuBuilder::ConfigParser.send(:setup_outfile, **args)
    refute_nil configs[:out]
    refute_nil configs[:out][:folder]
    assert_nil configs[:out][:file]
    assert_equal "/tmp", configs[:out][:folder]

    configs = {}
    args = {
     options: {out: "/home/user"},
     configs: configs
    }
    RokuBuilder::ConfigParser.send(:setup_outfile, **args)
    refute_nil configs[:out]
    refute_nil configs[:out][:folder]
    assert_nil configs[:out][:file]
    assert_equal "/home/user", configs[:out][:folder]

    configs = {}
    args = {
     options: {out: "/home/user/file.pkg"},
     configs: configs
    }
    RokuBuilder::ConfigParser.send(:setup_outfile, **args)
    refute_nil configs[:out]
    refute_nil configs[:out][:folder]
    refute_nil configs[:out][:file]
    assert_equal "/home/user", configs[:out][:folder]
    assert_equal "file.pkg", configs[:out][:file]

    configs = {}
    args = {
     options: {out: "/home/user/file.zip"},
     configs: configs
    }
    RokuBuilder::ConfigParser.send(:setup_outfile, **args)
    refute_nil configs[:out]
    refute_nil configs[:out][:folder]
    refute_nil configs[:out][:file]
    assert_equal "/home/user", configs[:out][:folder]
    assert_equal "file.zip", configs[:out][:file]

    configs = {}
    args = {
     options: {out: "/home/user/file.jpg"},
     configs: configs
    }
    RokuBuilder::ConfigParser.send(:setup_outfile, **args)
    refute_nil configs[:out]
    refute_nil configs[:out][:folder]
    refute_nil configs[:out][:file]
    assert_equal "/home/user", configs[:out][:folder]
    assert_equal "file.jpg", configs[:out][:file]

    configs = {}
    args = {
     options: {out: "file.jpg"},
     configs: configs
    }
    RokuBuilder::ConfigParser.send(:setup_outfile, **args)
    refute_nil configs[:out]
    refute_nil configs[:out][:folder]
    refute_nil configs[:out][:file]
    assert_equal "/tmp", configs[:out][:folder]
    assert_equal "file.jpg", configs[:out][:file]
  end
end
