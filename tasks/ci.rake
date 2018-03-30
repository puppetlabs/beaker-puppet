require 'rake/clean'
require 'pp'
require 'yaml'
require 'securerandom'
require 'fileutils'
require 'beaker-hostgenerator'
require 'beaker/dsl/install_utils'
extend Beaker::DSL::InstallUtils

REPO_CONFIGS_DIR = 'repo-configs'
CLEAN.include('*.tar', REPO_CONFIGS_DIR, 'tmp', '.beaker')

# Default test target if none specified
# TODO There are some projects that do not need to test against a master. It
# might be worth it to distinguish between these two scenarios so that we are
# maximizing our available resources. As it, we are allocating a master for all
# runs. Luckily, that master is also classified as an agent, so it's not a total
# waste of resources.
DEFAULT_MASTER_TEST_TARGET = 'redhat7-64m'
DEFAULT_TEST_TARGETS = "#{DEFAULT_MASTER_TEST_TARGET}a-windows2012r2-64a"

USAGE = <<-EOS
Usage: bundle exec rake <target> [arguments]

where <target> is one of:

  ci:test:git
  ci:test:aio
  ci:test:gem

See `bundle exec rake -D <target>` for information about each target. Each rake
task accepts the following environment variables:

REQUIRED
--------

SHA:
    The git SHA of either the puppet-agent package or component repo must be
    specified depending on the target. The `git` and `gem` use the component
    SHA, where as `aio` uses the puppet-agent package SHA.

OPTIONAL
--------

HOSTS:
    The hosts to run against. Must be specified as a path to a file or a
    beaker-hostgenerator string. Defaults to #{DEFAULT_TEST_TARGETS}.

    HOSTS=mynodes.yaml
    HOSTS=redhat7-64ma

TESTS:
    A comma-delimited list of files/directories containing tests to run.
    Defaults to running all tests.

    TESTS=tests/cycle_detection.rb
    TESTS=tests/pluginsync,tests/language

OPTIONS:
    Additional options to pass to beaker. Defaults to ''.

    OPTIONS='--dry-run --no-color'

BEAKER_HOSTS:
    Same as HOSTS.

TEST_TARGET:
    A beaker-hostgenerator string of agent-only hosts to run against.
    The MASTER_TEST_TARGET host will be added this list. This option is
    only intended to be used in CI.

MASTER_TEST_TARGET:
    Override the default master test target. Should only be used with
    TEST_TARGET, and is only intended to be used in CI. Defaults to
    #{DEFAULT_MASTER_TEST_TARGET}.
EOS

namespace :ci do
  desc "Print usage information"
  task :help do
    puts USAGE
    exit 1
  end

  task :check_env do
    if ENV['SHA'].nil?
      puts "Error: A SHA must be specified"
      puts "\n"
      puts USAGE
      exit 1
    end

    if ENV['TESTS'].nil?
      ENV['TESTS'] ||= ENV['TEST']
      ENV['TESTS'] ||= 'tests'
    end
  end

  task :gen_hosts do
    hosts =
      if ENV['HOSTS']
        ENV['HOSTS']
      elsif ENV['BEAKER_HOSTS']
        ENV['BEAKER_HOSTS']
      elsif env_config = ENV['CONFIG']
        puts 'Warning: environment variable CONFIG deprecated. Please use HOSTS to match beaker options.'
        env_config
      else
        # By default we assume TEST_TARGET is an agent-only string
        if agent_target = ENV['TEST_TARGET']
          master_target = ENV['MASTER_TEST_TARGET'] || DEFAULT_MASTER_TEST_TARGET
          "#{master_target}-#{agent_target}"
        else
          DEFAULT_TEST_TARGETS
        end
      end

    if File.exists?(hosts)
      ENV['HOSTS'] = hosts
    else
      hosts_file = "tmp/#{hosts}-#{SecureRandom.uuid}.yaml"
      cli = BeakerHostGenerator::CLI.new([hosts, '--disable-default-role', '--osinfo-version', '1'])
      FileUtils.mkdir_p('tmp') # -p ignores when dir already exists
      File.open(hosts_file, 'w') do |fh|
        fh.print(cli.execute)
      end
      ENV['HOSTS'] = hosts_file
    end
  end

  namespace :test do
    desc <<-EOS
Run the acceptance tests using puppet-agent (AIO) packages.

  $ SHA=<full sha> bundle exec rake ci:test:aio

SHA should be the full SHA for the puppet-agent package.
EOS
    task :aio => ['ci:check_env', 'ci:gen_hosts'] do
      beaker_suite(:aio)
    end

    desc <<-EOS
Run the acceptance tests against puppet gem on various platforms, performing a
basic smoke test.

  $ SHA=<full sha> bundle exec rake:ci:gem

SHA should be the full SHA for the component.
EOS
    task :gem => ['ci:check_env'] do
      beaker(:init, '--hosts', 'config/nodes/gem.yaml', '--options-file', 'config/gem/options.rb')
      beaker(:provision)
      beaker(:exec, 'pre-suite', '--pre-suite', pre_suites(:gem))
      beaker(:exec, "#{File.dirname(__dir__)}/setup/gem/010_GemInstall.rb")
      beaker(:destroy)
    end

    desc <<-EOS
Run the acceptance tests against a git checkout.

  $ SHA=<full sha> bundle exec rake ci:test:git

SHA should be the full SHA for the component. Other options:

FORK: to test against your fork, defaults to 'puppetlabs'

SERVER: to git fetch from an alternate GIT server, defaults to 'github.com'
EOS
    task :git => ['ci:check_env', 'ci:gen_hosts'] do
      beaker_suite(:git)
    end
  end

  task :test_and_preserve_hosts => ['ci:check_env', 'ci:gen_hosts'] do
    puts "WARNING, the test_and_preserve_hosts task is deprecated, use ci:test:aio instead."
    Rake::Task['ci:test:aio'].execute
  end
end

task :default do
  sh('rake -T')
end

task :spec do
  sh('rspec lib')
end

def beaker(command, *argv)
  argv.concat(ENV['OPTIONS'].split(' ')) if ENV['OPTIONS']

  sh('beaker', command.to_s, *argv)
end

def beaker_suite(type)
  beaker(:init, '--hosts', ENV['HOSTS'], '--options-file', "config/#{String(type)}/options.rb")
  beaker(:provision)
  beaker(:exec, 'pre-suite', '--pre-suite', pre_suites(type))
  beaker(:exec, 'pre-suite')
  beaker(:exec, ENV['TESTS'])
  beaker(:exec, 'post-suite')
  beaker(:destroy)
end

def pre_suites(type)
  beaker_root = Pathname.new(File.dirname(__dir__)).relative_path_from(Pathname.new(Dir.pwd))

  presuites = case type
  when :aio
    [
      "#{beaker_root}/setup/common/000-delete-puppet-when-none.rb",
      "#{beaker_root}/setup/aio/010_Install_Puppet_Agent.rb",
      "#{beaker_root}/setup/aio/011_Install_Puppet_Server.rb",
      "#{beaker_root}/setup/aio/012_Finalize_Installs.rb",
      "#{beaker_root}/setup/aio/020_InstallCumulusModules.rb",
      "#{beaker_root}/setup/aio/021_InstallAristaModuleMasters.rb",
      "#{beaker_root}/setup/aio/022_InstallAristaModuleAgents.rb",
      "#{beaker_root}/setup/common/025_StopFirewall.rb",
      "#{beaker_root}/setup/common/030_StopSssd.rb",
      "#{beaker_root}/setup/common/040_ValidateSignCert.rb",
      "#{beaker_root}/setup/aio/045_EnsureMasterStarted.rb",
    ]
  when :gem
    [
      "#{beaker_root}/setup/common/000-delete-puppet-when-none.rb",
      "#{beaker_root}/setup/git/000_EnvSetup.rb",
    ]
  when :git
    [
      "#{beaker_root}/setup/common/000-delete-puppet-when-none.rb",
      "#{beaker_root}/setup/git/000_EnvSetup.rb",
      "#{beaker_root}/setup/git/010_TestSetup.rb",
      "#{beaker_root}/setup/git/011_SetMaster.rb",
      "#{beaker_root}/setup/git/020_PuppetUserAndGroup.rb",
      "#{beaker_root}/setup/common/025_StopFirewall.rb",
      "#{beaker_root}/setup/git/030_PuppetMasterSanity.rb",
      "#{beaker_root}/setup/common/040_ValidateSignCert.rb",
      "#{beaker_root}/setup/git/060_InstallModules.rb",
      "#{beaker_root}/setup/git/070_InstallCACerts.rb",
    ]
  end
  presuites.join(',')
end
