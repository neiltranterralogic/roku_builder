# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

class ConfigParserTest < Minitest::Test
  def test_manifest_config
    options = {
      sideload: true
    }
    config = good_config
    configs = RokuBuilder::ConfigParser.parse(options: options, config: config)

    assert_equal Hash, config.class
    assert_equal "/tmp", configs[:manifest_config][:root_dir]
  end

  def test_manifest_config_in
    options = {
      in: "/dev/null/infile",
      sideload: true
    }
    config = good_config
    configs = RokuBuilder::ConfigParser.parse(options: options, config: config)

    assert_equal Hash, config.class
    assert_equal "/dev/null/infile", configs[:manifest_config][:root_dir]
    assert_equal :in, configs[:stage_config][:method]
  end

  def test_manifest_config_in_expand
    options = {
      in: "./infile",
      sideload: true
    }
    config = good_config
    configs = RokuBuilder::ConfigParser.parse(options: options, config: config)

    assert_equal Hash, config.class
    assert_equal File.join(Dir.pwd, "infile"), configs[:manifest_config][:root_dir]
    assert_equal :in, configs[:stage_config][:method]
  end

  def test_manifest_config_current
    options = {
      current: true,
      sideload: true
    }
    configs = nil
    config = good_config
    Pathname.stub(:pwd, "/dev/null/infile") do
      File.stub(:exist?, true) do
        configs = RokuBuilder::ConfigParser.parse(options: options, config: config)
      end
    end

    assert_equal Hash, config.class
    assert_equal "/dev/null/infile", configs[:manifest_config][:root_dir]
    assert_equal :current, configs[:stage_config][:method]
  end

  def test_setup_project_config_bad_project
    config = good_config
    options = {sideload: true, project: :project3}
    assert_raises RokuBuilder::ParseError do
      File.stub(:exist?, true) do
        RokuBuilder::ConfigParser.parse(options: options, config: config)
      end
    end
  end

  def test_setup_project_config_current
    options =  { sideload: true, current: true }
    config = good_config
    configs = nil
    File.stub(:exist?, true) do
      configs = RokuBuilder::ConfigParser.parse(options: options, config: config)
    end
    project = configs[:project_config]
    assert_equal Pathname.pwd.to_s, project[:directory]
    assert_equal :current, project[:stage_method]
    assert_nil project[:folders]
    assert_nil project[:files]
  end

  def test_setup_project_config_good_project_dir
    config = good_config
    options =  {sideload: true, project: :project1}
    File.stub(:exist?, true) do
      RokuBuilder::ConfigParser.parse(options: options, config: config)
    end
  end

  def test_setup_project_config_bad_project_dir
    config = good_config
    config[:projects][:project1][:directory] = "/dev/null"
    options = {sideload: true, project: :project1}
    assert_raises RokuBuilder::ParseError do
      File.stub(:exist?, true) do
        RokuBuilder::ConfigParser.parse(options: options, config: config)
      end
    end
  end

  def test_setup_project_config_bad_child_project_dir
    config = good_config
    config[:projects][:project_dir] = "/tmp"
    config[:projects][:project1][:directory] = "bad"
    options = {sideload: true, project: :project1}
    assert_raises RokuBuilder::ParseError do
      File.stub(:exist?, true) do
        RokuBuilder::ConfigParser.parse(options: options, config: config)
      end
    end
  end

  def test_setup_project_config_bad_parent_project_dir
    config = good_config
    config[:projects][:project_dir] = "/bad"
    config[:projects][:project1][:directory] = "good"
    options = {sideload: true, project: :project1}
    assert_raises RokuBuilder::ParseError do
      File.stub(:exist?, true) do
        RokuBuilder::ConfigParser.parse(options: options, config: config)
      end
    end
  end

  def test_setup_stage_config_bad_stage
    config = good_config
    options = {sideload: true, project: :project1, stage: :bad}
    assert_raises RokuBuilder::ParseError do
      File.stub(:exist?, true) do
        RokuBuilder::ConfigParser.parse(options: options, config: config)
      end
    end
  end

  def test_setup_stage_config_bad_method
    config = good_config
    config[:projects][:project1][:stage_method] = :bad
    options = {sideload: true, project: :project1}
    assert_raises RokuBuilder::ParseError do
      File.stub(:exist?, true) do
        RokuBuilder::ConfigParser.parse(options: options, config: config)
      end
    end
  end

  def test_setup_stage_config_missing_method
    config = good_config
    config[:projects][:project1][:stage_method] = nil
    options = {sideload: true, project: :project1}
    assert_raises RokuBuilder::ParseError do
      File.stub(:exist?, true) do
        RokuBuilder::ConfigParser.parse(options: options, config: config)
      end
    end
  end

  def test_setup_stage_config_script
    config = good_config
    config[:projects][:project1][:stage_method] = :script
    config[:projects][:project1][:stages][:production][:script] = {stage: "script", unstage: "script"}
    options = {stage: "production", sideload: true}
    parsed = RokuBuilder::ConfigParser.parse(options: options, config: config)
    assert_equal parsed[:project_config][:stages][:production][:script], config[:projects][:project1][:stages][:production][:script]
  end

  def test_setup_stage_config_git_ref
    config = good_config
    options = {stage: "production", ref: "git-ref", sideload: true}
    parsed = RokuBuilder::ConfigParser.parse(options: options, config: config)
    assert_equal options[:ref], parsed[:stage_config][:key]
  end

  def test_manifest_config_project_select
    options = { sideload: true }
    config = good_config
    configs = nil
    Pathname.stub(:pwd, Pathname.new("/dev/nuller")) do
      configs = RokuBuilder::ConfigParser.parse(options: options, config: config)
    end
    assert_equal Hash, config.class
    assert_equal "/tmp", configs[:project_config][:directory]
  end

  def test_manifest_config_project_directory
    options = {
      sideload: true
    }
    config = good_config
    config[:projects][:project_dir] = "/tmp"
    config[:projects][:project1][:directory] = "project1"
    config[:projects][:project2][:directory] = "project2"

    configs = nil

    Dir.stub(:exist?, true) do
      configs = RokuBuilder::ConfigParser.parse(options: options, config: config)
    end

    assert_equal Hash, config.class
    assert_equal "/tmp/project1", configs[:project_config][:directory]
  end

  def test_manifest_config_project_directory_select
    options = {sideload: true}
    config = good_config
    config[:projects][:project_dir] = "/tmp"
    config[:projects][:project1][:directory] = "project1"
    config[:projects][:project2][:directory] = "project2"

    configs = nil
    Pathname.stub(:pwd, Pathname.new("/tmp/project2")) do
      Dir.stub(:exist?, true) do
        configs = RokuBuilder::ConfigParser.parse(options: options, config: config)
      end
    end

    assert_equal Hash, config.class
    assert_equal "/tmp/project2", configs[:project_config][:directory]
  end

  def test_key_config_key_directory
    tmp_file = Tempfile.new("pkg")
    options = {key: true, project: :project2}
    config = good_config
    config[:keys][:key_dir] = File.dirname(tmp_file.path)
    config[:keys][:a][:keyed_pkg] = File.basename(tmp_file.path)

    configs = RokuBuilder::ConfigParser.parse(options: options, config: config)

    assert_equal Hash, config.class
    assert_equal tmp_file.path, configs[:key][:keyed_pkg]
    tmp_file.close
  end

  def test_key_config_key_directory_bad
    tmp_file = Tempfile.new("pkg")
    options = {key: true, project: :project2}
    config = good_config
    config[:keys][:key_dir] = "/bad"
    config[:keys][:a][:keyed_pkg] = File.basename(tmp_file.path)

    assert_raises RokuBuilder::ParseError do
      RokuBuilder::ConfigParser.parse(options: options, config: config)
    end
  end

  def test_key_config_key_path_bad
    tmp_file = Tempfile.new("pkg")
    options = {key: true, project: :project2}
    config = good_config
    config[:keys][:key_dir] = File.dirname(tmp_file.path)
    config[:keys][:a][:keyed_pkg] = File.basename(tmp_file.path)+".bad"

    assert_raises RokuBuilder::ParseError do
      RokuBuilder::ConfigParser.parse(options: options, config: config)
    end
  end

  def test_key_config_bad_key
    options = {key: true, project: :project1}
    config = good_config
    config[:projects][:project1][:stages][:production][:key] = "bad"

    assert_raises RokuBuilder::ParseError do
      RokuBuilder::ConfigParser.parse(options: options, config: config)
    end
  end

  def test_setup_sideload_config
    config = good_config
    options = {sideload: true}
    parsed = RokuBuilder::ConfigParser.parse(options: options, config: config)

    refute_nil parsed[:sideload_config]
    refute_nil parsed[:sideload_config][:content]
    refute_nil parsed[:build_config]
    refute_nil parsed[:build_config][:content]
    refute_nil parsed[:init_params][:loader]
    refute_nil parsed[:init_params][:loader][:root_dir]

    assert_nil parsed[:sideload_config][:content][:excludes]
    assert_nil parsed[:sideload_config][:update_manifest]
    assert_nil parsed[:sideload_config][:infile]
  end
  def test_setup_sideload_config_exclude
    config = good_config
    config[:projects][:project1][:excludes] = []
    options = {sideload: true}
    parsed = RokuBuilder::ConfigParser.parse(options: options, config: config)
    assert_nil parsed[:sideload_config][:content][:excludes]

    options = {build: true}
    parsed = RokuBuilder::ConfigParser.parse(options: options, config: config)
    refute_nil parsed[:sideload_config][:content][:excludes]

    options = {package: true}
    parsed = RokuBuilder::ConfigParser.parse(options: options, config: config)
    refute_nil parsed[:sideload_config][:content][:excludes]

    options = {sideload: true, exclude: true}
    parsed = RokuBuilder::ConfigParser.parse(options: options, config: config)
    refute_nil parsed[:sideload_config][:content][:excludes]
  end

  def test_deeplink_app_config
    config = good_config
    options = {deeplink: "a:b", app_id: "xxxxxx"}
    parsed = RokuBuilder::ConfigParser.parse(options: options, config: config)

    assert_equal parsed[:deeplink_config][:options], options[:deeplink]
    assert_equal parsed[:deeplink_config][:app_id], options[:app_id]
  end

  def test_monitor_config
    config = good_config
    options = {monitor: "main", regexp: "^A$"}
    parsed = RokuBuilder::ConfigParser.parse(options: options, config: config)
    refute_nil parsed[:monitor_config][:regexp]
    assert parsed[:monitor_config][:regexp].match("A")
  end

  def test_outfile_config
    config = good_config
    options =  {out: nil}
    parsed = RokuBuilder::ConfigParser.parse(options: options, config: config)

    refute_nil parsed[:out]
    refute_nil parsed[:out][:folder]
    assert_nil parsed[:out][:file]
    assert_equal "/tmp", parsed[:out][:folder]

    options = {out: "/home/user"}
    parsed = RokuBuilder::ConfigParser.parse(options: options, config: config)
    refute_nil parsed[:out]
    refute_nil parsed[:out][:folder]
    assert_nil parsed[:out][:file]
    assert_equal "/home/user", parsed[:out][:folder]

    options = {out: "/home/user/file.pkg"}
    parsed = RokuBuilder::ConfigParser.parse(options: options, config: config)
    refute_nil parsed[:out]
    refute_nil parsed[:out][:folder]
    refute_nil parsed[:out][:file]
    assert_equal "/home/user", parsed[:out][:folder]
    assert_equal "file.pkg", parsed[:out][:file]

    options = {out: "/home/user/file.zip"}
    parsed = RokuBuilder::ConfigParser.parse(options: options, config: config)
    refute_nil parsed[:out]
    refute_nil parsed[:out][:folder]
    refute_nil parsed[:out][:file]
    assert_equal "/home/user", parsed[:out][:folder]
    assert_equal "file.zip", parsed[:out][:file]

    options = {out: "/home/user/file.jpg"}
    parsed = RokuBuilder::ConfigParser.parse(options: options, config: config)
    refute_nil parsed[:out]
    refute_nil parsed[:out][:folder]
    refute_nil parsed[:out][:file]
    assert_equal "/home/user", parsed[:out][:folder]
    assert_equal "file.jpg", parsed[:out][:file]

    options = {out: "file.jpg"}
    parsed = RokuBuilder::ConfigParser.parse(options: options, config: config)
    refute_nil parsed[:out]
    refute_nil parsed[:out][:folder]
    refute_nil parsed[:out][:file]
    assert_equal "/tmp", parsed[:out][:folder]
    assert_equal "file.jpg", parsed[:out][:file]
  end
end
