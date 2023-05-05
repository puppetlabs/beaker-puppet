require 'rspec/core/rake_task'
require 'securerandom'
require 'beaker-hostgenerator'

namespace :test do
  namespace :spec do
    desc 'Run spec tests'
    RSpec::Core::RakeTask.new(:run) do |t|
      t.rspec_opts = ['--color']
      t.pattern = 'spec/'
    end

    desc 'Run spec tests with coverage'
    RSpec::Core::RakeTask.new(:coverage) do |t|
      ENV['BEAKER_PUPPET_COVERAGE'] = 'y'
      t.rspec_opts = ['--color']
      t.pattern = 'spec/'
    end
  end

  namespace :acceptance do
    USAGE = <<~EOS
      You may set BEAKER_HOSTS=config/nodes/foo.yaml or include it in an acceptance-options.rb for Beaker,
      or specify TEST_TARGET in a form beaker-hostgenerator accepts, e.g. ubuntu1504-64a.
      You may override the default master test target by specifying MASTER_TEST_TARGET.
      You may set TESTS=path/to/test,and/more/tests.
      You may set additional Beaker OPTIONS='--more --options'
      If there is a Beaker options hash in a ./acceptance/local_options.rb, it will be included.
      Commandline options set through the above environment variables will override settings in this file.
    EOS

    desc <<~EOS
      Run the puppet beaker acceptance tests on a puppet gem install.
      #{USAGE}
    EOS
    task gem: 'gen_hosts' do
      beaker_test(:gem)
    end

    desc <<~EOS
      Run the puppet beaker acceptance tests on a puppet git install.
      #{USAGE}
    EOS
    task git: 'gen_hosts' do
      beaker_test(:git)
    end

    desc <<~EOS
      Run the puppet beaker acceptance tests on a puppet package install.
      #{USAGE}
    EOS
    task pkg: 'gen_hosts' do
      beaker_test(:pkg)
    end

    desc <<~EOS
      Run the puppet beaker acceptance tests on a base system (no install).
      #{USAGE}
    EOS
    task base: 'gen_hosts' do
      beaker_test
    end

    desc 'Generate Beaker Host Config File'
    task :gen_hosts do
      next if hosts_file_env

      cli = BeakerHostGenerator::CLI.new([test_targets])
      FileUtils.mkdir_p('tmp') # -p ignores when dir already exists
      File.open("tmp/#{HOSTS_FILE}", 'w') do |fh|
        fh.print(cli.execute)
      end
    end

    def hosts_opt(use_preserved_hosts = false)
      if use_preserved_hosts
        "--hosts=#{HOSTS_PRESERVED}"
      elsif hosts_file_env
        "--hosts=#{hosts_file_env}"
      else
        "--hosts=tmp/#{HOSTS_FILE}"
      end
    end

    def hosts_file_env
      ENV.fetch('BEAKER_HOSTS', nil)
    end

    def agent_target
      ENV['TEST_TARGET'] || 'redhat7-64af'
    end

    def master_target
      ENV['MASTER_TEST_TARGET'] || 'redhat7-64default.mdcal'
    end

    def test_targets
      ENV['LAYOUT'] || "#{master_target}-#{agent_target}"
    end

    HOSTS_FILE = "#{test_targets}-#{SecureRandom.uuid}.yaml"
    HOSTS_PRESERVED = 'log/latest/hosts_preserved.yml'

    def beaker_test(mode = :base, options = {})
      preserved_hosts_mode = options[:hosts] == HOSTS_PRESERVED
      final_options = HarnessOptions.final_options(mode, options)

      options_opt = ''
      # preserved hosts can not be used with an options file (BKR-670)
      #   one can still use OPTIONS

      unless preserved_hosts_mode
        options_file = 'merged_options.rb'
        options_opt  = "--options-file=#{options_file}"
        File.open(options_file, 'w') do |merged|
          merged.puts <<~EOS
            # Copy this file to local_options.rb and adjust as needed if you wish to run
            # with some local overrides.
          EOS
          merged.puts(final_options)
        end
      end

      tests = ENV['TESTS'] || ENV.fetch('TEST', nil)
      tests_opt = ''
      tests_opt = "--tests=#{tests}" if tests

      overriding_options = ENV['OPTIONS'].to_s

      args = [options_opt, hosts_opt(preserved_hosts_mode), tests_opt,
              *overriding_options.split(' '),].compact

      sh('beaker', *args)
    end

    module HarnessOptions
      defaults = {
        tests: ['tests'],
        log_level: 'debug',
        preserve_hosts: 'onfail',
      }

      DEFAULTS = defaults

      def self.get_options(file_path)
        puts "Attempting to merge config file: #{file_path}"
        if File.exist? file_path
          options = eval(File.read(file_path), binding)
        else
          puts "No options file found at #{File.expand_path(file_path)}... skipping"
        end
        options || {}
      end

      def self.get_mode_options(mode)
        get_options("./acceptance/config/#{mode}/acceptance-options.rb")
      end

      def self.get_local_options
        get_options('./acceptance/local_options.rb')
      end

      def self.final_options(mode, intermediary_options = {})
        mode_options = get_mode_options(mode)
        local_overrides = get_local_options
        final_options = DEFAULTS.merge(mode_options)
        final_options.merge!(intermediary_options)
        final_options.merge!(local_overrides)
      end
    end
  end
end

# namespace-named default tasks.
# these are the default tasks invoked when only the namespace is referenced.
# they're needed because `task :default` in those blocks doesn't work as expected.
task 'test:spec' => 'test:spec:run'
task 'test:acceptance' => 'test:acceptance:quick'

# global defaults
task test: 'test:spec'
task default: :test

begin
  require 'github_changelog_generator/task'
rescue LoadError
  # GCG is an optional group
else
  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    config.header = "# Changelog\n\nAll notable changes to this project will be documented in this file."
    config.exclude_labels = %w[duplicate question invalid wontfix wont-fix skip-changelog]
    config.user = 'voxpupuli'
    config.project = 'beaker-puppet'
    config.future_release = "#{Gem::Specification.load("#{config.project}.gemspec").version}"
  end
end

begin
  require 'rubocop/rake_task'
rescue LoadError
  # RuboCop is an optional group
else
  RuboCop::RakeTask.new(:rubocop) do |task|
    # These make the rubocop experience maybe slightly less terrible
    task.options = ['--display-cop-names', '--display-style-guide', '--extra-details']
  end
end
