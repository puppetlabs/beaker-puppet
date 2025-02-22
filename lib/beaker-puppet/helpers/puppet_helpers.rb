require 'timeout'
require 'resolv'

module Beaker
  module DSL
    module Helpers
      # Methods that help you interact with your puppet installation, puppet must be installed
      # for these methods to execute correctly
      module PuppetHelpers
        # Return the regular expression pattern for an IPv4 address
        def ipv4_regex
          /(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/
        end

        # Return the IP address that given hostname returns when resolved on
        # the given host.
        #
        # @ param [Host] host One object that acts like a Beaker::Host
        # @ param [String] hostname The hostname to perform a DNS resolution on
        #
        # @return [String, nil] An IP address, or nil.
        def resolve_hostname_on(host, hostname)
          match = curl_on(host, "--verbose #{hostname}", accept_all_exit_codes: true).stderr.match(ipv4_regex)
          match ? match[0] : nil
        end

        # @!macro [new] common_opts
        #   @param [Hash{Symbol=>String}] opts Options to alter execution.
        #   @option opts [Boolean] :silent (false) Do not produce log output
        #   @option opts [Array<Fixnum>] :acceptable_exit_codes ([0]) An array
        #     (or range) of integer exit codes that should be considered
        #     acceptable.  An error will be thrown if the exit code does not
        #     match one of the values in this list.
        #   @option opts [Boolean] :accept_all_exit_codes (false) Consider all
        #     exit codes as passing.
        #   @option opts [Boolean] :dry_run (false) Do not actually execute any
        #     commands on the SUT
        #   @option opts [String] :stdin (nil) Input to be provided during command
        #     execution on the SUT.
        #   @option opts [Boolean] :pty (false) Execute this command in a pseudoterminal.
        #   @option opts [Boolean] :expect_connection_failure (false) Expect this command
        #     to result in a connection failure, reconnect and continue execution.
        #   @option opts [Hash{String=>String}] :environment ({}) These will be
        #     treated as extra environment variables that should be set before
        #     running the command.
        #

        # Read a setting from the puppet master config
        #
        # @param [Host] host The host
        # @param [String] setting The setting to read
        #
        def puppet_config(host, setting, section: nil)
          command = "config print #{setting}"
          command += " --section #{section}" if section

          on(host, puppet(command)).stdout.strip
        end

        # Return the name of the puppet user.
        #
        # @param [Host] host One object that acts like a Beaker::Host
        #
        # @note This method assumes puppet is installed on the host.
        #
        def puppet_user(host)
          puppet_config(host, 'user', section: 'master')
        end

        # Return the name of the puppet group.
        #
        # @param [Host] host One object that acts like a Beaker::Host
        #
        # @note This method assumes puppet is installed on the host.
        #
        def puppet_group(host)
          puppet_config(host, 'group', section: 'master')
        end

        # Test Puppet running in a certain run mode with specific options.
        # This ensures the following steps are performed:
        # 1. The pre-test Puppet configuration is backed up
        # 2. Lay down a new Puppet configuraton file
        # 3. Puppet is started or restarted in the specified run mode
        # 4. Ensure Puppet has started correctly
        # 5. Further tests are yielded to
        # 6. Revert Puppet to the pre-test state
        # 7. Testing artifacts are saved in a folder named for the test
        #
        # @param [Host] host        One object that act like Host
        #
        # @param [Hash{Symbol=>String}] conf_opts  Represents puppet settings.
        #                            Sections of the puppet.conf may be
        #                            specified, if no section is specified the
        #                            a puppet.conf file will be written with the
        #                            options put in a section named after [mode]
        # @option conf_opts [String] :__commandline_args__  A special setting for
        #                            command_line arguments such as --debug or
        #                            --logdest, which cannot be set in
        #                            puppet.conf. For example:
        #
        #                            :__commandline_args__ => '--logdest /tmp/a.log'
        #
        #                            These will only be applied when starting a FOSS
        #                            master, as a pe master is just bounced.
        # @option conf_opts [Boolean] :restart_when_done  determines whether a restart
        #                            should be run after the test has been yielded to.
        #                            Will stop puppet if false. Default behavior
        #                            is to restart, but you can override this on the
        #                            host or with this option.
        # @param [File] testdir      The temporary directory which will hold backup
        #                            configuration, and other test artifacts.
        #
        # @param [Block]             block The point of this method, yields so
        #                            tests may be ran. After the block is finished
        #                            puppet will revert to a previous state.
        #
        # @example A simple use case to ensure a master is running
        #     with_puppet_running_on( master ) do
        #         ...tests that require a master...
        #     end
        #
        # @example Fully utilizing the possiblities of config options
        #     with_puppet_running_on( master,
        #                             :main => {:logdest => '/var/blah'},
        #                             :master => {:masterlog => '/elswhere'},
        #                             :agent => {:server => 'localhost'} ) do
        #
        #       ...tests to be run...
        #     end
        #
        def with_puppet_running_on(host, conf_opts, testdir = host.tmpdir(File.basename(@path)), &block)
          unless conf_opts.is_a?(Hash)
            raise(ArgumentError,
                  "with_puppet_running_on's conf_opts must be a Hash. You provided a #{conf_opts.class}: '#{conf_opts}'")
          end

          cmdline_args = conf_opts[:__commandline_args__]
          restart_when_done = true
          restart_when_done = host[:restart_when_done] if host.has_key?(:restart_when_done)
          restart_when_done = conf_opts.fetch(:restart_when_done, restart_when_done)
          conf_opts = conf_opts.reject do |k, v|
            %i[__commandline_args__ restart_when_done].include?(k)
          end

          curl_retries = host['master-start-curl-retries'] || options['master-start-curl-retries']
          logger.debug "Setting curl retries to #{curl_retries}"

          if options[:is_puppetserver] || host[:is_puppetserver]
            confdir = puppet_config(host, 'confdir', section: 'master')
            vardir = puppet_config(host, 'vardir', section: 'master')

            if cmdline_args
              split_args = cmdline_args.split

              split_args.each do |arg|
                case arg
                when /--confdir=(.*)/
                  confdir = ::Regexp.last_match(1)
                when /--vardir=(.*)/
                  vardir = ::Regexp.last_match(1)
                end
              end
            end

            puppetserver_opts = {
              'jruby-puppet' => {
                'master-conf-dir' => confdir,
                'master-var-dir' => vardir,
              },
              'certificate-authority' => {
                'allow-subject-alt-names' => true,
              },
            }

            puppetserver_conf = File.join("#{host['puppetserver-confdir']}", 'puppetserver.conf')
            modify_tk_config(host, puppetserver_conf, puppetserver_opts)
          end
          begin
            backup_file = backup_the_file(host,
                                          puppet_config(host, 'confdir', section: 'master'),
                                          testdir,
                                          'puppet.conf')
            lay_down_new_puppet_conf(host, conf_opts, testdir)
            bounce_service(host, host['puppetservice'], curl_retries)

            yield self if block_given?

            # FIXME: these test-flow-control exceptions should be using throw
            # they can be caught in test_case.  current layout dows not allow it
          rescue Beaker::DSL::Outcomes::PassTest => early_assertion
            pass_test(early_assertion)
          rescue Beaker::DSL::Outcomes::FailTest => early_assertion
            fail_test(early_assertion)
          rescue Beaker::DSL::Outcomes::PendingTest => early_assertion
            pending_test(early_assertion)
          rescue Beaker::DSL::Outcomes::SkipTest => early_assertion
            skip_test(early_assertion)
          rescue Beaker::DSL::Assertions, Minitest::Assertion => early_assertion
            fail_test(early_assertion)
          rescue Exception => early_exception
            original_exception = RuntimeError.new("PuppetAcceptance::DSL::Helpers.with_puppet_running_on failed (check backtrace for location) because: #{early_exception}\n#{early_exception.backtrace.join("\n")}\n")
            raise(original_exception)
          ensure
            begin
              restore_puppet_conf_from_backup(host, backup_file)
              if restart_when_done
                bounce_service(host, host['puppetservice'], curl_retries)
              else
                host.exec puppet_resource('service', host['puppetservice'], 'ensure=stopped')
              end
            rescue Exception => teardown_exception
              begin
                dump_puppet_log(host) unless host.is_pe?
              rescue Exception => dumping_exception
                logger.error("Raised during attempt to dump puppet logs: #{dumping_exception}")
              end

              raise teardown_exception unless original_exception

              logger.error("Raised during attempt to teardown with_puppet_running_on: #{teardown_exception}\n---\n")
              raise original_exception
            end
          end
        end

        # Test Puppet running in a certain run mode with specific options,
        # on the default host
        # @see #with_puppet_running_on
        def with_puppet_running(conf_opts, testdir = host.tmpdir(File.basename(@path)), &block)
          with_puppet_running_on(default, conf_opts, testdir, &block)
        end

        # @!visibility private
        def restore_puppet_conf_from_backup(host, backup_file)
          puppet_conf = puppet_config(host, 'config', section: 'master')

          if backup_file
            host.exec(Command.new("if [ -f '#{backup_file}' ]; then " +
                                        "cat '#{backup_file}' > " +
                                        "'#{puppet_conf}'; " +
                                        "rm -f '#{backup_file}'; " +
                                    'fi'))
          else
            host.exec(Command.new("rm -f '#{puppet_conf}'"))
          end
        end

        # @!visibility private
        def stop_puppet_from_source_on(host)
          pid = host.exec(Command.new('cat `puppet config print --section master pidfile`')).stdout.chomp
          host.exec(Command.new("kill #{pid}"))
          Timeout.timeout(10) do
            while host.exec(Command.new("kill -0 #{pid}"), acceptable_exit_codes: [0, 1]).exit_code == 0
              # until kill -0 finds no process and we know that puppet has finished cleaning up
              sleep 1
            end
          end
        end

        # @!visibility private
        def dump_puppet_log(host)
          syslogfile = case host['platform']
                       when /fedora|centos|el|redhat|scientific/ then '/var/log/messages'
                       when /ubuntu|debian/ then '/var/log/syslog'
                       else return
                       end

          logger.notify "\n*************************"
          logger.notify '* Dumping master log    *'
          logger.notify '*************************'
          host.exec(Command.new("tail -n 100 #{syslogfile}"), acceptable_exit_codes: [0, 1])
          logger.notify "*************************\n"
        end

        # @!visibility private
        def lay_down_new_puppet_conf(host, configuration_options, testdir)
          puppetconf_main = puppet_config(host, 'config', section: 'master')
          puppetconf_filename = File.basename(puppetconf_main)
          puppetconf_test = File.join(testdir, puppetconf_filename)

          new_conf = puppet_conf_for(host, configuration_options)
          create_remote_file host, puppetconf_test, new_conf.to_s

          host.exec(
            Command.new("cat #{puppetconf_test} > #{puppetconf_main}"),
            silent: true,
          )
          host.exec(Command.new("cat #{puppetconf_main}"))
        end

        # @!visibility private
        def puppet_conf_for(host, conf_opts)
          puppetconf = host.exec(Command.new("cat #{puppet_config(host, 'config', section: 'master')}")).stdout
          BeakerPuppet::IniFile.new(default: 'main', content: puppetconf).merge(conf_opts)
        end

        # Restarts the named puppet service
        #
        # @param [Host] host Host the service runs on
        # @param [String] service Name of the service to restart
        # @param [Fixnum] curl_retries Number of seconds to wait for the restart to complete before failing
        # @param [Fixnum] port Port to check status at
        #
        # @return [Result] Result of last status check
        # @!visibility private
        def bounce_service(host, service, curl_retries = nil, port = nil)
          curl_retries = 120 if curl_retries.nil?
          port = options[:puppetserver_port] if port.nil?
          result = host.exec(Command.new("service #{service} reload"), acceptable_exit_codes: [0, 1, 3])
          return result if result.exit_code == 0

          host.exec puppet_resource('service', service, 'ensure=stopped')
          host.exec puppet_resource('service', service, 'ensure=running')

          curl_with_retries(" #{service} ", host, "https://localhost:#{port}", [35, 60], curl_retries)
        end

        # Runs 'puppet apply' on a remote host, piping manifest through stdin
        #
        # @param [Host] host The host that this command should be run on
        #
        # @param [String] manifest The puppet manifest to apply
        #
        # @!macro common_opts
        # @option opts [Boolean]  :parseonly (false) If this key is true, the
        #                          "--parseonly" command line parameter will
        #                          be passed to the 'puppet apply' command.
        #
        # @option opts [Boolean]  :trace (false) If this key exists in the Hash,
        #                         the "--trace" command line parameter will be
        #                         passed to the 'puppet apply' command.
        #
        # @option opts [Array<Integer>] :acceptable_exit_codes ([0]) The list of exit
        #                          codes that will NOT raise an error when found upon
        #                          command completion.  If provided, these values will
        #                          be combined with those used in :catch_failures and
        #                          :expect_failures to create the full list of
        #                          passing exit codes.
        #
        # @option opts [Hash]     :environment Additional environment variables to be
        #                         passed to the 'puppet apply' command
        #
        # @option opts [Boolean]  :catch_failures (false) By default `puppet
        #                         --apply` will exit with 0, which does not count
        #                         as a test failure, even if there were errors or
        #                         changes when applying the manifest. This option
        #                         enables detailed exit codes and causes a test
        #                         failure if `puppet --apply` indicates there was
        #                         a failure during its execution.
        #
        # @option opts [Boolean]  :catch_changes (false) This option enables
        #                         detailed exit codes and causes a test failure
        #                         if `puppet --apply` indicates that there were
        #                         changes or failures during its execution.
        #
        # @option opts [Boolean]  :expect_changes (false) This option enables
        #                         detailed exit codes and causes a test failure
        #                         if `puppet --apply` indicates that there were
        #                         no resource changes during its execution.
        #
        # @option opts [Boolean]  :expect_failures (false) This option enables
        #                         detailed exit codes and causes a test failure
        #                         if `puppet --apply` indicates there were no
        #                         failure during its execution.
        #
        # @option opts [Boolean]  :future_parser (false) This option enables
        #                         the future parser option that is available
        #                         from Puppet verion 3.2
        #                         By default it will use the 'current' parser.
        #
        # @option opts [Boolean]  :noop (false) If this option exists, the
        #                         the "--noop" command line parameter will be
        #                         passed to the 'puppet apply' command.
        #
        # @option opts [String]   :modulepath The search path for modules, as
        #                         a list of directories separated by the system
        #                         path separator character. (The POSIX path separator
        #                         is ‘:’, and the Windows path separator is ‘;’.)
        #
        # @option opts [String]   :hiera_config The path of the hiera.yaml configuration.
        #
        # @option opts [String]   :debug (false) If this option exists,
        #                         the "--debug" command line parameter
        #                         will be passed to the 'puppet apply' command.
        # @option opts [Boolean] :run_in_parallel Whether to run on each host in parallel.
        #
        # @param [Block] block This method will yield to a block of code passed
        #                      by the caller; this can be used for additional
        #                      validation, etc.
        #
        # @return [Array<Result>, Result, nil] An array of results, a result
        #   object, or nil. Check {Beaker::Shared::HostManager#run_block_on} for
        #   more details on this.
        def apply_manifest_on(host, manifest, opts = {}, &block)
          block_on host, opts do |host|
            on_options = {}
            on_options[:acceptable_exit_codes] = Array(opts[:acceptable_exit_codes])

            puppet_apply_opts = {}
            if opts[:debug] || ENV['BEAKER_PUPPET_DEBUG']
              puppet_apply_opts[:debug] = nil
            else
              puppet_apply_opts[:verbose] = nil
            end
            puppet_apply_opts[:parseonly] = nil if opts[:parseonly]
            puppet_apply_opts[:trace] = nil if opts[:trace]
            puppet_apply_opts[:parser] = 'future' if opts[:future_parser]
            puppet_apply_opts[:modulepath] = opts[:modulepath] if opts[:modulepath]
            puppet_apply_opts[:hiera_config] = opts[:hiera_config] if opts[:hiera_config]
            puppet_apply_opts[:noop] = nil if opts[:noop]

            # From puppet help:
            # "... an exit code of '2' means there were changes, an exit code of
            # '4' means there were failures during the transaction, and an exit
            # code of '6' means there were both changes and failures."
            if [opts[:catch_changes], opts[:catch_failures], opts[:expect_failures],
                opts[:expect_changes],].compact.length > 1
              raise(ArgumentError,
                    'Cannot specify more than one of `catch_failures`, ' +
                    '`catch_changes`, `expect_failures`, or `expect_changes` ' +
                    'for a single manifest')
            end

            if opts[:catch_changes]
              puppet_apply_opts['detailed-exitcodes'] = nil

              # We're after idempotency so allow exit code 0 only.
              on_options[:acceptable_exit_codes] |= [0]
            elsif opts[:catch_failures]
              puppet_apply_opts['detailed-exitcodes'] = nil

              # We're after only complete success so allow exit codes 0 and 2 only.
              on_options[:acceptable_exit_codes] |= [0, 2]
            elsif opts[:expect_failures]
              puppet_apply_opts['detailed-exitcodes'] = nil

              # We're after failures specifically so allow exit codes 1, 4, and 6 only.
              on_options[:acceptable_exit_codes] |= [1, 4, 6]
            elsif opts[:expect_changes]
              puppet_apply_opts['detailed-exitcodes'] = nil

              # We're after changes specifically so allow exit code 2 only.
              on_options[:acceptable_exit_codes] |= [2]
            else
              # Either use the provided acceptable_exit_codes or default to [0]
              on_options[:acceptable_exit_codes] |= [0]
            end

            # Not really thrilled with this implementation, might want to improve it
            # later. Basically, there is a magic trick in the constructor of
            # PuppetCommand which allows you to pass in a Hash for the last value in
            # the *args Array; if you do so, it will be treated specially. So, here
            # we check to see if our caller passed us a hash of environment variables
            # that they want to set for the puppet command. If so, we set the final
            # value of *args to a new hash with just one entry (the value of which
            # is our environment variables hash)
            puppet_apply_opts['ENV'] = opts[:environment] if opts.has_key?(:environment)

            file_path = host.tmpfile(%(apply_manifest_#{Time.now.strftime('%H%M%S%L')}.pp))
            create_remote_file(host, file_path, manifest + "\n")

            if host[:default_apply_opts].respond_to? :merge
              puppet_apply_opts = host[:default_apply_opts].merge(puppet_apply_opts)
            end

            on host, puppet('apply', file_path, puppet_apply_opts), on_options, &block
          end
        end

        # Runs 'puppet apply' on default host, piping manifest through stdin
        # @see #apply_manifest_on
        def apply_manifest(manifest, opts = {}, &block)
          apply_manifest_on(default, manifest, opts, &block)
        end

        # @deprecated
        def run_agent_on(host, arg = '--no-daemonize --verbose --onetime --test',
                         options = {}, &block)
          block_on host do |host|
            on host, puppet_agent(arg), options, &block
          end
        end

        # This method using the puppet resource 'host' will setup host aliases
        # and register the remove of host aliases via Beaker::TestCase#teardown
        #
        # A teardown step is also added to make sure unstubbing of the host is
        # removed always.
        #
        # @param [Host, Array<Host>, String, Symbol] machine    One or more hosts to act upon,
        #                            or a role (String or Symbol) that identifies one or more hosts.
        # @param ip_spec [Hash{String=>String}] a hash containing the host to ip
        #   mappings
        # @param alias_spec [Hash{String=>Array[String]] an hash containing the host to alias(es) mappings to apply
        # @example Stub puppetlabs.com on the master to 127.0.0.1 with an alias example.com
        #   stub_hosts_on(master, {'puppetlabs.com' => '127.0.0.1'}, {'puppetlabs.com' => ['example.com']})
        def stub_hosts_on(machine, ip_spec, alias_spec = {})
          block_on machine do |host|
            ip_spec.each do |address, ip|
              aliases = alias_spec[address] || []
              manifest = <<-EOS.gsub /^\s+/, ''
                host { '#{address}':
                  \tensure       => present,
                  \tip           => '#{ip}',
                  \thost_aliases => #{aliases},
                }
              EOS
              logger.notify("Stubbing address #{address} to IP #{ip} on machine #{host}")
              apply_manifest_on(host, manifest)
            end

            teardown do
              ip_spec.each do |address, ip|
                logger.notify("Unstubbing address #{address} to IP #{ip} on machine #{host}")
                on(host, puppet('resource', 'host', address, 'ensure=absent'))
              end
            end
          end
        end

        # This method accepts a block and using the puppet resource 'host' will
        # setup host aliases before and after that block.
        #
        # @param [Host, Array<Host>, String, Symbol] host    One or more hosts to act upon,
        #                            or a role (String or Symbol) that identifies one or more hosts.
        # @param ip_spec [Hash{String=>String}] a hash containing the host to ip
        #   mappings
        # @param alias_spec [Hash{String=>Array[String]] an hash containing the host to alias(es) mappings to apply
        # @example Stub forgeapi.puppetlabs.com on the master to 127.0.0.1 with an alias forgeapi.example.com
        #   with_host_stubbed_on(master, {'forgeapi.puppetlabs.com' => '127.0.0.1'}, {'forgeapi.puppetlabs.com' => ['forgeapi.example.com']}) do
        #     puppet( "module install puppetlabs-stdlib" )
        #   end
        def with_host_stubbed_on(host, ip_spec, alias_spec = {}, &block)
          block_on host do |host|
            # this code is duplicated from the `stub_hosts_on` method. The
            # `stub_hosts_on` method itself is not used here because this
            # method is used by modules tests using `beaker-rspec`. Since
            # the `stub_hosts_on` method contains a `teardown` step, it is
            # incompatible with `beaker_rspec`.
            ip_spec.each do |address, ip|
              aliases = alias_spec[address] || []
              manifest = <<-EOS.gsub /^\s+/, ''
                  host { '#{address}':
                    \tensure       => present,
                    \tip           => '#{ip}',
                    \thost_aliases => #{aliases},
                  }
              EOS
              logger.notify("Stubbing address #{address} to IP #{ip} on machine #{host}")
              apply_manifest_on(host, manifest)
            end
          end

          block.call
        ensure
          ip_spec.each do |address, ip|
            logger.notify("Unstubbing address #{address} to IP #{ip} on machine #{host}")
            on(host, puppet('resource', 'host', address, 'ensure=absent'))
          end
        end

        # This method accepts a block and using the puppet resource 'host' will
        # setup host aliases before and after that block on the default host
        #
        # @example Stub puppetlabs.com on the default host to 127.0.0.1
        #   stub_hosts('puppetlabs.com' => '127.0.0.1')
        # @see #stub_hosts_on
        def stub_hosts(ip_spec)
          stub_hosts_on(default, ip_spec)
        end

        # This wraps the method `stub_hosts_on` and makes the stub specific to
        # the forge alias.
        #
        # forge api v1 canonical source is forge.puppetlabs.com
        # forge api v3 canonical source is forgeapi.puppetlabs.com
        #
        # @deprecated this method should not be used because stubbing the host
        # breaks TLS validation.
        #
        # @param machine [String] the host to perform the stub on
        # @param forge_host [String] The URL to use as the forge alias, will default to using :forge_host in the
        #                             global options hash
        def stub_forge_on(machine, forge_host = nil)
          # use global options hash
          primary_forge_name = 'forge.puppetlabs.com'
          forge_host ||= options[:forge_host]
          forge_ip = resolve_hostname_on(machine, forge_host)
          raise "Failed to resolve forge host '#{forge_host}'" unless forge_ip

          @forge_ip ||= forge_ip
          block_on machine do |host|
            stub_hosts_on(host, { primary_forge_name => @forge_ip },
                          { primary_forge_name => ['forge.puppet.com', 'forgeapi.puppetlabs.com', 'forgeapi.puppet.com'] })
          end
        end

        # This wraps the method `with_host_stubbed_on` and makes the stub specific to
        # the forge alias.
        #
        # forge api v1 canonical source is forge.puppetlabs.com
        # forge api v3 canonical source is forgeapi.puppetlabs.com
        #
        # @deprecated this method should not be used because stubbing the host
        # breaks TLS validation.
        #
        # @param host [String] the host to perform the stub on
        # @param forge_host [String] The URL to use as the forge alias, will default to using :forge_host in the
        #                             global options hash
        def with_forge_stubbed_on(host, forge_host = nil, &block)
          # use global options hash
          primary_forge_name = 'forge.puppetlabs.com'
          forge_host ||= options[:forge_host]
          forge_ip = resolve_hostname_on(host, forge_host)
          raise "Failed to resolve forge host '#{forge_host}'" unless forge_ip

          @forge_ip ||= forge_ip
          with_host_stubbed_on(host, { primary_forge_name => @forge_ip },
                               { primary_forge_name => ['forge.puppet.com', 'forgeapi.puppetlabs.com', 'forgeapi.puppet.com'] }, &block)
        end

        # This wraps `with_forge_stubbed_on` and provides it the default host
        # @see with_forge_stubbed_on
        #
        # @deprecated this method should not be used because stubbing the host
        # breaks TLS validation.
        def with_forge_stubbed(forge_host = nil, &block)
          with_forge_stubbed_on(default, forge_host, &block)
        end

        # This wraps the method `stub_hosts` and makes the stub specific to
        # the forge alias.
        #
        # @deprecated this method should not be used because stubbing the host
        # breaks TLS validation.
        #
        # @see #stub_forge_on
        def stub_forge(forge_host = nil)
          # use global options hash
          forge_host ||= options[:forge_host]
          stub_forge_on(default, forge_host)
        end

        # Waits until a successful curl check has happened against puppetdb
        #
        # @param [Host] host Host puppetdb is on
        # @param [Fixnum] nonssl_port Port to make the HTTP status check over
        # @param [Fixnum] ssl_port Port to make the HTTPS status check over
        #
        # @return [Result] Result of the last HTTPS status check
        def sleep_until_puppetdb_started(host, nonssl_port = nil, ssl_port = nil)
          nonssl_port = options[:puppetdb_port_nonssl] if nonssl_port.nil?
          ssl_port = options[:puppetdb_port_ssl] if ssl_port.nil?
          pe_ver = host['pe_ver'] || '0'
          if version_is_less(pe_ver, '2016.1.0')
            # the status endpoint was introduced in puppetdb 4.0. The earliest
            # PE release with the 4.x pdb version was 2016.1.0
            endpoint = 'pdb/meta/v1/version'
            expected_regex = '\"version\" \{0,\}: \{0,\}\"[0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\"'
          else
            endpoint = 'status/v1/services/puppetdb-status'
            expected_regex = '\"state\" \{0,\}: \{0,\}\"running\"'
          end
          retry_on(host,
                   "curl -m 1 http://localhost:#{nonssl_port}/#{endpoint} | grep '#{expected_regex}'",
                   { max_retries: 120 })
          curl_with_retries('start puppetdb (ssl)',
                            host, "https://#{host.node_name}:#{ssl_port}", [35, 60])
        end

        # Waits until a successful curl check has happened against puppetserver
        #
        # @param [Host] host Host puppetserver is on
        # @param [Fixnum] port Port to make the HTTPS status check over
        #
        # @return [Result] Result of the last HTTPS status check
        def sleep_until_puppetserver_started(host, port = nil)
          port = options[:puppetserver_port] if port.nil?
          curl_with_retries('start puppetserver (ssl)',
                            host, "https://#{host.node_name}:#{port}", [35, 60])
        end

        # Waits until a successful curl check has happaned against node classifier
        #
        # @param [Host] host Host node classifier is on
        # @param [Fixnum] port Port to make the HTTPS status check over
        #
        # @return [Result] Result of the last HTTPS status check
        def sleep_until_nc_started(host, port = nil)
          port = options[:nodeclassifier_port] if port.nil?
          curl_with_retries('start nodeclassifier (ssl)',
                            host, "https://#{host.node_name}:#{port}", [35, 60])
        end

        # stops the puppet agent running on the host
        # @param [Host, Array<Host>, String, Symbol] agent    One or more hosts to act upon,
        #                            or a role (String or Symbol) that identifies one or more hosts.
        # @param [Hash{Symbol=>String}] opts Options to alter execution.
        # @option opts [Boolean] :run_in_parallel Whether to run on each host in parallel.
        def stop_agent_on(agent, opts = {})
          block_on agent, opts do |host|
            vardir = host.puppet_configprint['vardir']

            # In 4.0 this was changed to just be `puppet`
            agent_service = 'puppet'
            unless aio_version?(host)
              # The agent service is `pe-puppet` everywhere EXCEPT certain linux distros on PE 2.8
              # In all the case that it is different, this init script will exist. So we can assume
              # that if the script doesn't exist, we should just use `pe-puppet`
              agent_service = 'pe-puppet-agent'
              agent_service = 'pe-puppet' unless host.file_exist?('/etc/init.d/pe-puppet-agent')
            end

            # Under a number of stupid circumstances, we can't stop the
            # agent using puppet.  This is usually because of issues with
            # the init script or system on that particular configuration.
            avoid_puppet_at_all_costs = false
            avoid_puppet_at_all_costs ||= host['platform'] =~ /el-4/
            avoid_puppet_at_all_costs ||= host['pe_ver'] && version_is_less(host['pe_ver'],
                                                                            '3.2') && host['platform'] =~ /sles/

            if avoid_puppet_at_all_costs
              # When upgrading, puppet is already stopped. On EL4, this causes an exit code of '1'
              on host, "/etc/init.d/#{agent_service} stop", acceptable_exit_codes: [0, 1]
            else
              on host, puppet_resource('service', agent_service, 'ensure=stopped')
            end

            # Ensure that a puppet run that was started before the last lock check is completed
            agent_running = true
            while agent_running
              agent_running = host.file_exist?("#{vardir}/state/agent_catalog_run.lock")
              sleep 2 if agent_running
            end
          end
        end

        # stops the puppet agent running on the default host
        # @see #stop_agent_on
        def stop_agent
          stop_agent_on(default)
        end

        # wait for a given host to appear in the dashboard
        # @deprecated this method should be removed in the next release since we don't believe the check is necessary.
        def wait_for_host_in_dashboard(host)
          hostname = host.node_name
          hostcert = dashboard.puppet['hostcert']
          key = dashboard.puppet['hostprivkey']
          cacert = dashboard.puppet['localcacert']
          retry_on(dashboard, "curl --cert #{hostcert} --key #{key} --cacert #{cacert}\
                              https://#{dashboard}:4433/classifier-api/v1/nodes | grep '\"name\":\"#{hostname}\"'")
        end

        # Ensure the host has requested a cert, then sign it
        #
        # @param [Host, Array<Host>, String, Symbol] host   One or more hosts, or a role (String or Symbol)
        #                            that identifies one or more hosts to validate certificate signing.
        #                            No argument, or an empty array means no validation of success
        #                            for specific hosts will be performed.
        # @return nil
        # @raise [FailTest] if process times out
        def sign_certificate_for(host = [])
          hostnames = []
          hosts = host.is_a?(Array) ? host : [host]
          hosts.each do |current_host|
            if [master, dashboard, database].include? current_host
              on(current_host, puppet('agent -t'), acceptable_exit_codes: [0, 1, 2])
              on(master, "puppetserver ca sign --certname #{current_host}")
            else
              hostnames << Regexp.escape(current_host.node_name)
            end
          end

          if hostnames.size < 1
            on(master, 'puppetserver ca sign --all', acceptable_exit_codes: [0, 24])
            return
          end

          while hostnames.size > 0
            last_sleep = 0
            next_sleep = 1
            11.times do |i|
              if i == 10
                fail_test("Failed to sign cert for #{hostnames}")
                hostnames.clear
              end
              on(master, 'puppetserver ca sign --all', acceptable_exit_codes: [0, 24])
              out = on(master, 'puppetserver ca list --all').stdout
              if out !~ /.*Requested.*/ && hostnames.all? { |hostname| out =~ /\b#{hostname}\b/ }
                hostnames.clear
                break
              end

              sleep next_sleep
              (last_sleep, next_sleep) = next_sleep, last_sleep + next_sleep
            end
          end
          host
        end

        # prompt the master to sign certs then check to confirm the cert for the default host is signed
        # @see #sign_certificate_for
        def sign_certificate
          sign_certificate_for(default)
        end

        # Create a temp directory on remote host, optionally owned by specified user and group.
        #
        # @param [Host, Array<Host>, String, Symbol] hosts One or more hosts to act upon,
        # or a role (String or Symbol) that identifies one or more hosts.
        # @param [String] path_prefix A remote path prefix for the new temp directory.
        # @param [String] user The name of user that should own the temp directory. If
        # not specified, uses default permissions from tmpdir creation.
        # @param [String] group The name of group that should own the temp directory.
        # If not specified, uses default permissions from tmpdir creation.
        #
        # @return [String, Array<String>] Returns the name of the newly-created dir, or
        # an array of names of newly-created dirs per-host
        #
        # @note While tempting, this method should not be "optimized" to coalesce calls to
        # chown user:group when both options are passed, as doing so will muddy the spec.
        def create_tmpdir_on(hosts, path_prefix = '', user = nil, group = nil)
          block_on hosts do |host|
            # create the directory
            dir = host.tmpdir(path_prefix)
            # only chown if explicitly passed; don't make assumptions about perms
            # only `chown user` for cleaner codepaths
            if user
              # ensure user exists
              unless host.user_get(user).success?
                # clean up
                host.rm_rf("#{dir}")
                raise "User #{user} does not exist on #{host}."
              end
              # chown only user
              host.chown(user, dir)
              # on host, "chown #{user} #{dir}"
            end
            # only chgrp if explicitly passed; don't make assumptions about perms
            if group
              # ensure group exists
              unless host.group_get(group).success?
                # clean up
                # on host, "rmdir #{dir}"
                host.rm_rf(dir)
                raise "Group #{group} does not exist on #{host}."
              end
              # chgrp
              # on host, "chgrp #{group} #{dir}"
              host.chgrp(group, dir)
            end
            dir
          end
        end

        # Create a temp directory on remote host with a user.  Default user
        # is puppet master user.
        #
        # @param [Host] host A single remote host on which to create and adjust
        # the ownership of a temp directory.
        # @param [String] name A remote path prefix for the new temp
        # directory. Default value is '/tmp/beaker'
        # @param [String] user The name of user that should own the temp
        # directory. If no username is specified, use `puppet config print user
        # --section master` to obtain username from master. Raise RuntimeError
        # if this puppet command returns a non-zero exit code.
        #
        # @return [String] Returns the name of the newly-created dir.
        def create_tmpdir_for_user(host, name = '/tmp/beaker', user = nil)
          user ||= puppet_config(host, 'user', section: 'master')
          create_tmpdir_on(host, name, user)
        end
      end
    end
  end
end
