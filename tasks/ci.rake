require 'rake/clean'
require 'pp'
require 'yaml'
require 'securerandom'
require 'fileutils'
require 'tempfile'
require 'beaker-hostgenerator'
require 'beaker/dsl/install_utils'
extend Beaker::DSL::InstallUtils

REPO_CONFIGS_DIR = 'repo-configs'
CLEAN.include('*.tar', REPO_CONFIGS_DIR, 'tmp', '.beaker', 'log', 'junit')

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

  ci:test:setup
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

DEV_BUILDS_URL:
    Override the url where we look for development builds of packages to test.
    Defaults to https://builds.delivery.puppetlabs.net

NIGHTLY_BUILDS_URL:
    Override the url where we look for nightly builds of packages to test.
    Defaults to https://nightlies.puppet.com

RELEASE_STREAM
    The release stream for the puppet family you want to test. This defaults to 'puppet',
    which is the current latest release stream. Other options are currently published streams
    like 'puppet5' or 'puppet6'. This is currently only used when accessing repos on
    nightlies.puppet.com

SERVER_VERSION:
    The version of puppetserver to test against. This defaults to 'latest' if unset.
    When it defaults to latest, it will attept to pull packages from NIGHTLY_BUILDS_URL
    from the RELEASE_STREAM repo.

FORK:
    Used to build a github url. If unset, this defaults to 'puppetlabs'. This can be used to
    point acceptance to pull a repo to test from a personal fork.

$project_FORK:
    Similar to FORK, but project specific. If you have only one project (i.e., hiera) that you
    wanted to test from a different fork then all the others, you could set HIERA_FORK=melissa,
    you would get back 'https://github.com/melissa/hiera.git'.

SERVER:
    Used to build a github url. If unset, this defaults to 'github.com'. This can be used to
    pull a github repo from a unique server location.

$project_SERVER:
    Similar to SERVER, but project specific. If you have only one project (i.e., hiera) that you
    want to pull from a different server then all the others, you could set HIERA_SERVER=192.0.2.1,
    and you would get back 'https://192.0.2.1/puppetlabs-hiera.git'.

RUNTIME_BRANCH:
    Currently only used with git-based testing. This must correspond to a branch in the
    puppet-agent repo. We use it to determine the tag of the agent-runtime package that
    we want. We also use it to construct the agent-runtime archive name (ie agent-runtime-${branch}-${tag})
EOS

namespace :ci do
  desc "Print usage information"
  task :help do
    puts USAGE
    exit 1
  end

  task :check_env do
    sha = ENV['SHA']
    case sha
    when /^\d+\.\d+\.\d+$/
      # tags are ok
    when /^[0-9a-f]{40}$/
      # full SHAs are ok
    when nil
      puts "Error: A SHA must be specified"
      puts "\n"
      puts USAGE
      exit 1
    else
      puts "Error: Expected SHA to be a tag or 40 digit SHA, not '#{sha}'"
      puts "\n"
      puts USAGE
      exit 1
    end

    if ENV['TESTS'].nil?
      ENV['TESTS'] ||= ENV['TEST']
      ENV['TESTS'] ||= 'tests'
    end
  end

  task :gen_hosts, [:hypervisor] do |t, args|
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
      cli_args = [
        hosts,
        '--disable-default-role',
        '--osinfo-version', '1'
      ]
      if args[:hypervisor]
        cli_args += ['--hypervisor', args[:hypervisor]]
      end
      cli = BeakerHostGenerator::CLI.new(cli_args)
      FileUtils.mkdir_p('tmp') # -p ignores when dir already exists
      File.open(hosts_file, 'w') do |fh|
        fh.print(cli.execute)
      end
      ENV['HOSTS'] = hosts_file
    end
  end

  namespace :test do
    desc <<-EOS
Run the acceptance tests using puppet-agent (AIO) packages, with or without
retrying failed tests one time.

  $ SHA=<full sha> bundle exec rake ci:test:aio

or

  $ SHA=<full sha> bundle exec rake ci:test:aio[RETRIES]


SHA should be the full SHA for the puppet-agent package.

RETRIES should be set to true to retry failed tests one time. It defaults
to false.
EOS
    task :aio, [:retries] => ['ci:check_env', 'ci:gen_hosts'] do |t, args|
      args.with_defaults(retries: false)
      if args[:retries]
        beaker_suite_retry(:aio)
      else
        beaker_suite(:aio)
      end
    end

    desc <<-EOS
Setup acceptance tests using puppet-agent (AIO) packages.

  $ SHA=<tag or full sha> HOSTS=<hosts> bundle exec rake ci:test:setup

SHA should be the tag or full SHA for the puppet-agent package.

HOSTS can be a beaker-hostgenerator string or existing file.
EOS
    task :setup => ['ci:check_env'] do |t, args|
      unless ENV['HOSTS']
        case File.basename(Dir.pwd.sub(/\/acceptance$/, ''))
        when 'pxp-agent', 'puppet'
          ENV['HOSTS'] ||= 'redhat7-64m-redhat7-64a'
        else
          ENV['HOSTS'] ||= 'redhat7-64a'
        end
      end

      Rake::Task[:'ci:gen_hosts'].invoke('abs')
      beaker_setup(:aio)
      puts "\nSetup completed on:"
      YAML.load_file('.beaker/subcommand_options.yaml').fetch('HOSTS', {}).each_pair do |hostname, data|
        roles = data.fetch('roles', []).join(', ')
        puts "- #{hostname} (#{roles})"
      end
      puts "\nRun 'bundle exec beaker exec <path>' where <path> is a directory or comma-separated list of tests."
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
      begin
        beaker(:exec, 'pre-suite', '--preserve-state', '--pre-suite', pre_suites(:gem))
        beaker(:exec, "#{File.dirname(__dir__)}/setup/gem/010_GemInstall.rb")
      ensure
        preserve_hosts = ENV['OPTIONS'].include?('--preserve-hosts=always') if ENV['OPTIONS']
        beaker(:destroy) unless preserve_hosts
      end
    end

    desc <<-EOS
Run the acceptance tests against a git checkout.

  $ SHA=<full sha> bundle exec rake ci:test:git

SHA: for git based testing specifically, this can be a sha, a branch, or a tag.

FORK: to test against your fork, defaults to 'puppetlabs'

SERVER: to git fetch from an alternate GIT server, defaults to 'github.com'

RUNTIME_BRANCH: the branch of the agent-runtime package to grab, defaults to
  'master'. This tells us which branch of puppet-agent to get the runtime tag
  from and helps us create the archive name when we go to curl it down.
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

def beaker_setup(type)
  beaker(:init, '--hosts', ENV['HOSTS'], '--preserve-hosts', 'always', '--options-file', "config/#{String(type)}/options.rb")
  beaker(:provision)
  beaker(:exec, 'pre-suite', '--preserve-state', '--pre-suite', pre_suites(type))
  beaker(:exec, 'pre-suite', '--preserve-state')
end

def beaker_suite(type)
  beaker(:init, '--hosts', ENV['HOSTS'], '--options-file', "config/#{String(type)}/options.rb")
  beaker(:provision)

  begin
    beaker(:exec, 'pre-suite', '--preserve-state', '--pre-suite', pre_suites(type))
    beaker(:exec, 'pre-suite', '--preserve-state')
    beaker(:exec, ENV['TESTS'])
    beaker(:exec, 'post-suite')
  ensure
    preserve_hosts = ENV['OPTIONS'].include?('--preserve-hosts=always') if ENV['OPTIONS']
    beaker(:destroy) unless preserve_hosts
  end
end

def beaker_suite_retry(type)
  beaker(:init, '--hosts', ENV['HOSTS'], '--options-file', "config/#{String(type)}/options.rb")
  beaker(:provision)

  begin
    beaker(:exec, 'pre-suite', '--preserve-state', '--pre-suite', pre_suites(type))
    beaker(:exec, 'pre-suite', '--preserve-state')

    begin
      json_results_file = Tempfile.new
      beaker(:exec, ENV['TESTS'], '--test-results-file', json_results_file.path)
    rescue RuntimeError => e
      puts "ERROR: #{e.message}"
      tests_to_rerun = JSON.load(File.read(json_results_file.path))
      if tests_to_rerun.nil? || tests_to_rerun.empty?
        raise e
      else
        puts '*** Retrying the following:'
        puts tests_to_rerun.map { |spec| "  #{spec}" }
        beaker(:exec, tests_to_rerun.map { |str| "#{str}" }.join(',') )
      end
    end
  ensure
    beaker(:exec, 'post-suite')
    preserve_hosts = ENV['OPTIONS'].include?('--preserve-hosts=always') if ENV['OPTIONS']
    beaker(:destroy) unless preserve_hosts
  end
end

def pre_suites(type)
  beaker_root = Pathname.new(File.dirname(__dir__)).relative_path_from(Pathname.new(Dir.pwd))

  presuites = case type
  when :aio
    [
      "#{beaker_root}/setup/common/000-delete-puppet-when-none.rb",
      "#{beaker_root}/setup/common/003_solaris_cert_fix.rb",
      "#{beaker_root}/setup/common/005_redhat_subscription_fix.rb",
      "#{beaker_root}/setup/aio/010_Install_Puppet_Agent.rb",
      "#{beaker_root}/setup/common/011_Install_Puppet_Server.rb",
      "#{beaker_root}/setup/common/012_Finalize_Installs.rb",
      "#{beaker_root}/setup/common/020_InstallCumulusModules.rb",
      "#{beaker_root}/setup/common/021_InstallAristaModuleMasters.rb",
      "#{beaker_root}/setup/common/022_InstallAristaModuleAgents.rb",
      "#{beaker_root}/setup/common/025_StopFirewall.rb",
      "#{beaker_root}/setup/common/030_StopSssd.rb",
      "#{beaker_root}/setup/common/040_ValidateSignCert.rb",
      "#{beaker_root}/setup/common/045_EnsureMasterStarted.rb",
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
      "#{beaker_root}/setup/common/011_Install_Puppet_Server.rb",
      "#{beaker_root}/setup/git/020_PuppetUserAndGroup.rb",
      "#{beaker_root}/setup/git/070_InstallCACerts.rb",
      "#{beaker_root}/setup/common/025_StopFirewall.rb",
      "#{beaker_root}/setup/common/030_StopSssd.rb",
      "#{beaker_root}/setup/common/040_ValidateSignCert.rb",
      "#{beaker_root}/setup/common/045_EnsureMasterStarted.rb",
    ]
  end
  presuites.join(',')
end
