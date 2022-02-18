require 'spec_helper'

class ClassMixedWithDSLHelpers
  include Beaker::DSL::Helpers
  include Beaker::DSL::Wrappers
  include Beaker::DSL::Roles
  include Beaker::DSL::Patterns
  include Beaker::DSL::Outcomes
  include Beaker::DSL::Helpers::PuppetHelpers

  def logger
    RSpec::Mocks::Double.new('logger').as_null_object
  end

end

describe ClassMixedWithDSLHelpers do
  let( :opts )   { Beaker::Options::Presets.env_vars }
  let( :command ){ 'ls' }
  let( :host )   { double.as_null_object }
  let( :result ) { Beaker::Result.new( host, command ) }

  let( :master ) { make_host( 'master',   :roles => %w( master agent default)    ) }
  let( :agent )  { make_host( 'agent',    :roles => %w( agent )           ) }
  let( :custom ) { make_host( 'custom',   :roles => %w( custom agent )    ) }
  let( :dash )   { make_host( 'console',  :roles => %w( dashboard agent ) ) }
  let( :db )     { make_host( 'db',       :roles => %w( database agent )  ) }
  let( :hosts )  { [ master, agent, dash, db, custom ] }

  describe '#create_tmpdir_on' do
    let(:host) { {'user' => 'puppet', 'group' => 'muppets'} }
    let(:result_success) { double.as_null_object }
    let(:result_failure) { double.as_null_object }
    let(:tmpdir) { '/tmp/beaker.XXXXXX/' }

    before :each do
      allow( host ).to receive( :tmpdir ).and_return( tmpdir )
      allow( host ).to receive( :result ).and_return( result_success )
      allow( result_success ).to receive( :success? ).and_return( true )
      allow( result_success ).to receive( :stdout ).and_return( 'puppet' )
      allow( result_failure ).to receive( :success? ).and_return( false )
    end

    context 'with the path_prefix argument' do
      it 'passes path_prefix to host.tmpdir' do
        expect( host ).to receive( :tmpdir ).with( 'beaker' )
        subject.create_tmpdir_on( host, 'beaker' )
      end
    end

    context 'with the user argument' do
      it 'calls chown when a user is specified' do
        expect( host ).to receive( :user_get ).and_return( result_success )
        expect( host ).to receive( :chown ).with( host['user'], tmpdir )

        subject.create_tmpdir_on( host, 'beaker', host['user'] )
      end

      it 'does not call chown when a user is not specified' do
        expect( host ).to_not receive( :chown )

        subject.create_tmpdir_on( host, 'beaker' )
      end

      it 'does not call chown and cleans up when the user does not exist on the host' do
        expect( host ).to receive( :user_get ).and_return( result_failure )
        expect( host ).to receive( :rm_rf ).with( tmpdir )

        expect{
          subject.create_tmpdir_on( host, 'beaker', 'invalid.user' )
        }.to raise_error( RuntimeError, /User invalid.user does not exist on / )
      end
    end

    context 'with the group argument' do
      it 'calls chgrp when a group is specified' do
        expect( host ).to receive( :group_get ).and_return( result_success )
        expect( host ).to receive( :chgrp ).with( host['group'], tmpdir )

        subject.create_tmpdir_on( host, 'beaker', nil, host['group'] )
      end

      it 'does not call chgrp when a group is not specified' do
        expect( subject ).to_not receive( :chgrp )

        subject.create_tmpdir_on( host, 'beaker' )
      end

      it 'does not call chgrp and cleans up when the group does not exist on the host' do
        expect( host ).to receive( :group_get ).and_return( result_failure )
        expect( host ).to receive( :rm_rf ).with( tmpdir )

        expect{
          subject.create_tmpdir_on( host, 'beaker', nil, 'invalid.group' )
        }.to raise_error( RuntimeError, /Group invalid.group does not exist on / )
      end
    end

    context 'with user and group arguments' do
      # don't coalesce the group into chown, i.e. `chown user:group`
      # this keeps execution paths simple, clean, and discrete
      it 'calls chown and chgrp separately' do
        expect( host ).to receive( :user_get ).and_return( result_success )
        expect( host ).to receive( :group_get ).and_return( result_success )
        expect( host ).to receive( :chown ).with( host['user'], tmpdir )
        expect( host ).to receive( :chgrp ).with( host['group'], tmpdir )

        subject.create_tmpdir_on( host, 'beaker', host['user'], host['group'] )
      end

      it 'does not pass group to chown' do
        allow( host ).to receive( :user_get ).and_return( result_success )
        allow( host ).to receive( :chgrp ).with( host['group'], tmpdir )

        expect( host ).to receive( :group_get ).and_return( result_success )
        expect( host ).to receive( :chown ).with( host['user'], tmpdir )

        subject.create_tmpdir_on( host, 'beaker', host['user'], host['group'] )
      end
    end
  end

  describe '#create_tmpdir_for_user' do
    let(:host) { {} }
    let(:result) { double.as_null_object }

    before :each do
      allow(host).to receive(:result).and_return(result)
      allow(result).to receive(:exit_code).and_return(0)
      allow(result).to receive(:stdout).and_return('puppet')
    end

    context 'with no user argument' do

      context 'with no path name argument' do
        it 'executes chown once' do
          cmd = "the command"
          expect(Beaker::Command).to receive(:new).with(/puppet config print user --section master/, [], {"ENV"=>{}, :cmdexe=>true}).and_return(cmd)
          expect(subject).to receive(:on).with(host, cmd).and_return(result)
          expect(subject).to receive(:create_tmpdir_on).with(host, /\/tmp\/beaker/, /puppet/)
          subject.create_tmpdir_for_user(host)
        end
      end

      context 'with path name argument' do
        it 'executes chown once' do
          cmd = "the command"
          expect(Beaker::Command).to receive(:new).with(/puppet config print user --section master/, [], {"ENV"=>{}, :cmdexe=>true}).and_return(cmd)
          expect(subject).to receive(:on).with(host, cmd).and_return(result)
          expect(subject).to receive(:create_tmpdir_on).with(host, /\/tmp\/bogus/, /puppet/)
          subject.create_tmpdir_for_user(host, "/tmp/bogus")
        end
      end

    end

  end


  describe '#apply_manifest_on' do

    before :each do
      hosts.each do |host|
        allow( host ).to receive( :tmpfile )
      end
    end

    it 'calls puppet' do
      allow( subject ).to receive( :hosts ).and_return( hosts )
      expect( subject ).to receive( :create_remote_file ).and_return( true )
      expect( subject ).to receive( :puppet ).
      #  with( 'apply', '--verbose', 'agent' ).
        and_return( 'puppet_command' )

      expect( subject ).to receive( :on ).
        with( agent, 'puppet_command',
              {:acceptable_exit_codes => [0]} )

      subject.apply_manifest_on( agent, 'class { "boo": }')
    end

    it 'operates on an array of hosts' do
      allow( subject ).to receive( :hosts ).and_return( hosts )
      the_hosts = [master, agent]

      expect( subject ).to receive( :create_remote_file ).twice.and_return( true )
      the_hosts.each do |host|
        expect( subject ).to receive( :puppet ).
          and_return( 'puppet_command' )

        expect( subject ).to receive( :on ).
          with( host, 'puppet_command', {:acceptable_exit_codes => [0]} )
      end

      result = subject.apply_manifest_on( the_hosts, 'include foobar' )
      expect(result).to be_an(Array)
    end

    it 'operates on an array of hosts' do
      InParallel::InParallelExecutor.logger = logger
      FakeFS.deactivate!
      # This will only get hit if forking processes is supported and at least 2 items are being submitted to run in parallel
      # expect( InParallel::InParallelExecutor ).to receive(:_execute_in_parallel).with(any_args).and_call_original.exactly(2).times
      allow( subject ).to receive( :hosts ).and_return( hosts )
      the_hosts = [master, agent]

      allow( subject ).to receive( :create_remote_file ).and_return( true )
      allow( subject ).to receive( :puppet ).
        and_return( 'puppet_command' )
      the_hosts.each do |host|
        allow( subject ).to receive( :on ).
          with( host, 'puppet_command', {:acceptable_exit_codes => [0]} )
      end

      result = nil
      result = subject.apply_manifest_on( the_hosts, 'include foobar' )
      expect(result).to be_an(Array)
    end

    it 'runs block_on in parallel if set' do
      InParallel::InParallelExecutor.logger = logger
      FakeFS.deactivate!
      allow( subject ).to receive( :hosts ).and_return( hosts )
      the_hosts = [master, agent]

      allow( subject ).to receive( :create_remote_file ).and_return( true )
      allow( subject ).to receive( :puppet ).
        and_return( 'puppet_command' )
      the_hosts.each do |host|
        allow( subject ).to receive( :on ).
          with( host, 'puppet_command', {:acceptable_exit_codes => [0]} )
      end
      expect( subject ).to receive( :block_on ).with(
        anything,
        {:run_in_parallel => true}
      )

      subject.apply_manifest_on( the_hosts, 'include foobar', { :run_in_parallel => true } )
    end

    it 'adds acceptable exit codes with :catch_failures' do
      allow( subject ).to receive( :hosts ).and_return( hosts )
      expect( subject ).to receive( :create_remote_file ).and_return( true )
      expect( subject ).to receive( :puppet ).
        and_return( 'puppet_command' )

      expect( subject ).to receive( :on ).
        with( agent, 'puppet_command',
              {:acceptable_exit_codes => [0,2]} )

      subject.apply_manifest_on( agent,
                                'class { "boo": }',
                                {:catch_failures => true} )
    end
    it 'allows acceptable exit codes through :catch_failures' do
      allow( subject ).to receive( :hosts ).and_return( hosts )
      expect( subject ).to receive( :create_remote_file ).and_return( true )
      expect( subject ).to receive( :puppet ).
        and_return( 'puppet_command' )

      expect( subject ).to receive( :on ).
        with( agent, 'puppet_command',
             {:acceptable_exit_codes => [4,0,2]} )

      subject.apply_manifest_on( agent,
                                'class { "boo": }',
                                {:acceptable_exit_codes => [4],
                                 :catch_failures => true} )
    end
    it 'enforces a 0 exit code through :catch_changes' do
      allow( subject ).to receive( :hosts ).and_return( hosts )
      expect( subject ).to receive( :create_remote_file ).and_return( true )
      expect( subject ).to receive( :puppet ).
        and_return( 'puppet_command' )

      expect( subject ).to receive( :on ).with(
        agent,
        'puppet_command',
        {:acceptable_exit_codes => [0]}
      )

      subject.apply_manifest_on(
        agent,
        'class { "boo": }',
        {:catch_changes => true}
      )
    end
    it 'enforces a 2 exit code through :expect_changes' do
      allow( subject ).to receive( :hosts ).and_return( hosts )
      expect( subject ).to receive( :create_remote_file ).and_return( true )
      expect( subject ).to receive( :puppet ).
        and_return( 'puppet_command' )

      expect( subject ).to receive( :on ).with(
        agent,
        'puppet_command',
        {:acceptable_exit_codes => [2]}
      )

      subject.apply_manifest_on(
        agent,
        'class { "boo": }',
        {:expect_changes => true}
      )
    end
    it 'enforces exit codes through :expect_failures' do
      allow( subject ).to receive( :hosts ).and_return( hosts )
      expect( subject ).to receive( :create_remote_file ).and_return( true )
      expect( subject ).to receive( :puppet ).
        and_return( 'puppet_command' )

      expect( subject ).to receive( :on ).with(
        agent,
        'puppet_command',
        {:acceptable_exit_codes => [1,4,6]}
      )

      subject.apply_manifest_on(
        agent,
        'class { "boo": }',
        {:expect_failures => true}
      )
    end
    it 'enforces exit codes through :expect_failures' do
      allow( subject ).to receive( :hosts ).and_return( hosts )
      expect {
        subject.apply_manifest_on(
          agent,
          'class { "boo": }',
          :expect_failures => true,
          :catch_failures  => true
        )
      }.to raise_error ArgumentError, /catch_failures.+expect_failures/
    end
    it 'enforces added exit codes through :expect_failures' do
      allow( subject ).to receive( :hosts ).and_return( hosts )
      expect( subject ).to receive( :create_remote_file ).and_return( true )
      expect( subject ).to receive( :puppet ).
        and_return( 'puppet_command' )

      expect( subject ).to receive( :on ).with(
        agent,
        'puppet_command',
        {:acceptable_exit_codes => [1,2,3,4,5,6]}
      )

      subject.apply_manifest_on(
        agent,
        'class { "boo": }',
        {:acceptable_exit_codes => (1..5),
         :expect_failures       => true}
      )
    end

    it 'can set the --parser future flag' do
      allow( subject ).to receive( :hosts ).and_return( hosts )
      expect( subject ).to receive( :create_remote_file ).and_return( true )

      expect( subject ).to receive( :puppet ).with(
        'apply',
        anything,
        include(
          :parser => 'future',
          'detailed-exitcodes' => nil,
          :verbose => nil
        )
      )

      allow( subject ).to receive( :on )
      hosts.each do |host|
        allow( host ).to receive( :tmpfile ).and_return( 'pants' )
      end

      subject.apply_manifest_on(
        agent,
        'class { "boo": }',
        :acceptable_exit_codes => (1..5),
        :future_parser         => true,
        :expect_failures       => true
      )
    end

    it 'can set the --noops flag' do
      allow( subject ).to receive( :hosts ).and_return( hosts )
      expect( subject ).to receive( :create_remote_file ).and_return( true )

      expect( subject ).to receive( :puppet ).with(
        'apply',
        anything,
        include(
          :noop => nil,
          'detailed-exitcodes' => nil,
          :verbose => nil
        )
      )

      allow( subject ).to receive( :on )
      hosts.each do |host|
        allow( host ).to receive( :tmpfile ).and_return( 'pants' )
      end

      subject.apply_manifest_on(
        agent,
        'class { "boo": }',
        :acceptable_exit_codes => (1..5),
        :noop                  => true,
        :expect_failures       => true
      )
    end
  end

  it 'can set the --debug flag' do
    allow( subject ).to receive( :hosts ).and_return( hosts )
    allow( subject ).to receive( :create_remote_file ).and_return( true )
    allow( agent ).to receive( :tmpfile )
    allow( subject ).to receive( :on )

    expect( subject ).to receive( :puppet ).with(
      'apply',
      anything,
      include( :debug => nil )
    )

    subject.apply_manifest_on(
      agent,
      'class { "boo": }',
      :debug => true,
    )
  end

  describe "#apply_manifest" do
    it "delegates to #apply_manifest_on with the default host" do
      allow( subject ).to receive( :hosts ).and_return( hosts )
      # allow( subject ).to receive( :default ).and_return( master )

      expect( subject ).to receive( :default ).and_return( master )
      expect( subject ).to receive( :apply_manifest_on ).with( master, 'manifest', {:opt => 'value'}).once

      subject.apply_manifest( 'manifest', {:opt => 'value'}  )

    end
  end

  describe '#stub_hosts_on' do
    it 'executes puppet on the host passed and ensures it is reverted' do
      test_host = make_host('my_host', {})
      allow( subject ).to receive( :hosts ).and_return( hosts )
      logger = double.as_null_object

      expect( subject ).to receive( :on ).once
      allow( subject ).to receive( :logger ).and_return( logger )
      expect( subject ).to receive( :teardown ).and_yield
      manifest =<<-EOS.gsub /^\s+/, ""
        host { 'puppetlabs.com':
          \tensure       => present,
          \tip           => '127.0.0.1',
          \thost_aliases => [],
        }
      EOS
      expect( subject ).to receive( :apply_manifest_on ).once.
        with( test_host, manifest )
      expect( subject ).to receive( :puppet ).once.
        with( 'resource', 'host',
              'puppetlabs.com',
              'ensure=absent' )

      subject.stub_hosts_on( test_host, {'puppetlabs.com' => '127.0.0.1'} )
    end
    it 'adds aliases to defined hostname' do
      test_host = make_host('my_host', {})
      allow( subject ).to receive( :hosts ).and_return( hosts )
      logger = double.as_null_object

      expect( subject ).to receive( :on ).once
      allow( subject ).to receive( :logger ).and_return( logger )
      expect( subject ).to receive( :teardown ).and_yield
      manifest =<<-EOS.gsub /^\s+/, ""
        host { 'puppetlabs.com':
          \tensure       => present,
          \tip           => '127.0.0.1',
          \thost_aliases => [\"foo\", \"bar\"],
        }
      EOS
      expect( subject ).to receive( :apply_manifest_on ).once.
        with( test_host, manifest )

      subject.stub_hosts_on( test_host, {'puppetlabs.com' => '127.0.0.1'}, {'puppetlabs.com' => ['foo','bar']} )
    end
  end

  describe "#stub_hosts" do
    it "delegates to stub_hosts_on with the default host" do
      allow( subject ).to receive( :hosts ).and_return( hosts )

      expect( subject ).to receive( :default ).and_return( master )
      expect( subject ).to receive( :stub_hosts_on ).with( master, 'ipspec' ).once

      subject.stub_hosts( 'ipspec'  )

    end
  end

  describe '#stub_forge_on' do
    it 'stubs forge.puppetlabs.com with the value of `forge`' do
      allow( subject ).to receive( :resolve_hostname_on ).and_return ( '127.0.0.1' )
      host = make_host('my_host', {})
      expect( subject ).to receive( :stub_hosts_on ).
        with( host, {'forge.puppetlabs.com' => '127.0.0.1'}, {'forge.puppetlabs.com' => ['forge.puppet.com','forgeapi.puppetlabs.com','forgeapi.puppet.com']} )

      subject.stub_forge_on( host, 'my_forge.example.com' )
    end
  end

  describe "#stub_forge" do
    it "delegates to stub_forge_on with the default host" do
      allow( subject ).to receive( :options ).and_return( {} )
      allow( subject ).to receive( :hosts ).and_return( hosts )

      expect( subject ).to receive( :default ).and_return( master )
      expect( subject ).to receive( :stub_forge_on ).with( master, nil ).once

      subject.stub_forge( )

    end
  end

  describe "#stop_agent_on" do
    let( :result_fail ) { Beaker::Result.new( [], "" ) }
    let( :result_pass ) { Beaker::Result.new( [], "" ) }
    before :each do
      allow( subject ).to receive( :sleep ).and_return( true )
    end

    it 'runs the pe-puppet on a system without pe-puppet-agent' do
      vardir = '/var'
      deb_agent = make_host( 'deb', :platform => 'debian-7-amd64', :pe_ver => '3.7' )
      allow( deb_agent ).to receive( :puppet_configprint ).and_return( { 'vardir' => vardir } )

      expect( deb_agent ).to receive( :file_exist? ).with("/var/state/agent_catalog_run.lock").and_return(false)
      expect( deb_agent ).to receive( :file_exist? ).with("/etc/init.d/pe-puppet-agent").and_return(false)

      expect( subject ).to receive( :aio_version? ).with( deb_agent ).and_return( false )
      expect( subject ).to receive( :version_is_less ).with( deb_agent[:pe_ver], '3.2' ).and_return( false )
      expect( subject ).to receive( :puppet_resource ).with( "service", "pe-puppet", "ensure=stopped").once
      expect( subject ).to receive( :on ).once

      subject.stop_agent_on( deb_agent )

    end

    it 'runs the pe-puppet-agent on a unix system with pe-puppet-agent' do
      vardir = '/var'
      el_agent = make_host( 'el', :platform => 'el-5-x86_64', :pe_ver => '3.7' )
      allow( el_agent ).to receive( :puppet_configprint ).and_return( { 'vardir' => vardir } )

      expect( el_agent ).to receive( :file_exist? ).with("/var/state/agent_catalog_run.lock").and_return(false)
      expect( el_agent ).to receive( :file_exist? ).with("/etc/init.d/pe-puppet-agent").and_return(true)

      expect( subject ).to receive( :aio_version? ).with( el_agent ).and_return( false )
      expect( subject ).to receive( :version_is_less ).with( el_agent[:pe_ver], '3.2' ).and_return( false )
      expect( subject ).to receive( :puppet_resource ).with( "service", "pe-puppet-agent", "ensure=stopped").once
      expect( subject ).to receive( :on ).once

      subject.stop_agent_on( el_agent )
    end

    it 'runs puppet on a unix system 4.0 or newer' do
      vardir = '/var'
      el_agent = make_host( 'el', :platform => 'el-5-x86_64', :pe_ver => '4.0' )
      allow( el_agent ).to receive( :puppet_configprint ).and_return( { 'vardir' => vardir } )

      expect( el_agent ).to receive( :file_exist? ).with("/var/state/agent_catalog_run.lock").and_return(false)

      expect( subject ).to receive( :aio_version? ).with( el_agent ).and_return( true )
      expect( subject ).to receive( :version_is_less ).with( el_agent[:pe_ver], '3.2' ).and_return( false )
      expect( subject ).to receive( :puppet_resource ).with( "service", "puppet", "ensure=stopped").once
      expect( subject ).to receive( :on ).once

      subject.stop_agent_on( el_agent )
    end

    it 'can run on an array of hosts' do
      vardir = '/var'
      el_agent = make_host( 'el', :platform => 'el-5-x86_64', :pe_ver => '4.0' )
      el_agent2 = make_host( 'el', :platform => 'el-5-x86_64', :pe_ver => '4.0' )

      allow( el_agent ).to receive( :puppet_configprint ).and_return( { 'vardir' => vardir } )
      expect( el_agent ).to receive( :file_exist? ).with("/var/state/agent_catalog_run.lock").and_return(false)
      expect( subject ).to receive( :aio_version? ).with( el_agent ).and_return( true )
      expect( subject ).to receive( :version_is_less ).with( el_agent[:pe_ver], '3.2' ).and_return( false )

      allow( el_agent2 ).to receive( :puppet_configprint ).and_return( { 'vardir' => vardir } )
      expect( el_agent2 ).to receive( :file_exist? ).with("/var/state/agent_catalog_run.lock").and_return(false)
      expect( subject ).to receive( :aio_version? ).with( el_agent2 ).and_return( true )
      expect( subject ).to receive( :version_is_less ).with( el_agent2[:pe_ver], '3.2' ).and_return( false )

      expect( subject ).to receive( :puppet_resource ).with( "service", "puppet", "ensure=stopped").twice
      expect( subject ).to receive( :on ).twice

      subject.stop_agent_on( [el_agent, el_agent2] )
    end

    it 'runs in parallel with run_in_parallel=true' do
      InParallel::InParallelExecutor.logger = logger
      FakeFS.deactivate!
      vardir = '/var'
      el_agent = make_host( 'el', :platform => 'el-5-x86_64', :pe_ver => '4.0' )
      el_agent2 = make_host( 'el', :platform => 'el-5-x86_64', :pe_ver => '4.0' )

      allow( el_agent ).to receive( :puppet_configprint ).and_return( { 'vardir' => vardir } )
      allow( el_agent ).to receive( :file_exist? ).with("/var/state/agent_catalog_run.lock").and_return(false)

      allow( el_agent2 ).to receive( :puppet_configprint ).and_return( { 'vardir' => vardir } )
      allow( el_agent2 ).to receive( :file_exist? ).with("/var/state/agent_catalog_run.lock").and_return(false)

      # This will only get hit if forking processes is supported and at least 2 items are being submitted to run in parallel
      expect( subject ).to receive( :block_on ).with(
        anything,
        include( :run_in_parallel => true )
      )

      subject.stop_agent_on( [el_agent, el_agent2], { :run_in_parallel => true} )
    end

  end

  describe "#stop_agent" do
    it 'delegates to #stop_agent_on with default host' do
      allow( subject ).to receive( :hosts ).and_return( hosts )

      expect( subject ).to receive( :default ).and_return( master )
      expect( subject ).to receive( :stop_agent_on ).with( master ).once

      subject.stop_agent( )

    end
  end

  describe "#sign_certificate_for" do

    before :each do
      allow( subject ).to receive( :hosts ).and_return( hosts )
      allow( subject ).to receive( :master ).and_return( master )
      allow( subject ).to receive( :dashboard ).and_return( dash )
      allow( subject ).to receive( :database ).and_return( db )
      hosts.each do |host|
        allow( host ).to receive( :node_name ).and_return( '' )
      end
    end

    it 'signs certs with `puppetserver ca` in Puppet 6' do
      allow( subject ).to receive( :sleep ).and_return( true )

      result.stdout = "+ \"#{agent}\""

      allow( subject ).to receive( :puppet ) do |arg|
        arg
      end

      version_result = double("version", :stdout => "6.0.0")
      expect(subject).to receive(:on).with(master, '--version').and_return(version_result)
      expect(subject).to receive(:version_is_less).and_return(false)
      expect(subject).to receive(:on).with(master, 'puppetserver ca sign --all', :acceptable_exit_codes => [0, 24]).once
      expect(subject).to receive(:on).with(master, 'puppetserver ca list --all').once.and_return(result)

      subject.sign_certificate_for( agent )
    end

    it 'signs certs with `puppet cert` in Puppet 5' do
      allow( subject ).to receive( :sleep ).and_return( true )

      result.stdout = "+ \"#{agent}\""

      allow( subject ).to receive( :puppet ) do |arg|
        arg
      end

      version_result = double("version", :stdout => "5.0.0")
      expect(subject).to receive(:on).with(master, '--version').and_return(version_result)
      expect(subject).to receive(:version_is_less).and_return(true)
      expect(subject).to receive(:on).with(master, 'cert --sign --all --allow-dns-alt-names', :acceptable_exit_codes => [0, 24]).once
      expect(subject).to receive(:on).with(master, 'cert --list --all').once.and_return( result )

      subject.sign_certificate_for( agent )
    end

    it 'retries 11 times before quitting' do
      allow( subject ).to receive( :sleep ).and_return( true )

      result.stdout = "Requested Certificates: \"#{agent}\""
      allow( subject ).to receive( :hosts ).and_return( hosts )

      allow( subject ).to receive( :puppet ) do |arg|
        arg
      end

      version_result = double("version", :stdout => "6.0.0")
      expect(subject).to receive(:on).with(master, '--version').and_return(version_result)
      expect( subject ).to receive( :on ).with( master, 'puppetserver ca sign --all', :acceptable_exit_codes => [0, 24]).exactly( 11 ).times
      expect( subject ).to receive( :on ).with( master, 'puppetserver ca list --all').exactly( 11 ).times.and_return( result )
      expect( subject ).to receive( :fail_test ).once

      subject.sign_certificate_for( agent )
    end

    it 'accepts an array of hosts to validate' do
      allow( subject ).to receive( :sleep ).and_return( true )

      result.stdout = "+ \"#{agent}\" + \"#{custom}\""
      allow( subject ).to receive( :hosts ).and_return( hosts )

      allow( subject ).to receive( :puppet ) do |arg|
        arg
      end
      expect( subject ).to receive( :on ).with( master, "agent -t", :acceptable_exit_codes => [0, 1, 2]).once
      version_result = double("version", :stdout => "6.0.0")
      expect(subject).to receive(:on).with(master, '--version').and_return(version_result)
      expect( subject ).to receive( :on ).with( master, "puppetserver ca sign --certname master").once
      expect( subject ).to receive( :on ).with( master, "puppetserver ca sign --all", :acceptable_exit_codes => [0, 24]).once
      expect( subject ).to receive( :on ).with( master, "puppetserver ca list --all").once.and_return( result )

      subject.sign_certificate_for( [master, agent, custom] )
    end
  end

  describe "#sign_certificate" do
    it 'delegates to #sign_certificate_for with the default host' do
      allow( subject ).to receive( :hosts ).and_return( hosts )
      expect( subject ).to receive( :default ).and_return( master )

      expect( subject ).to receive( :sign_certificate_for ).with( master ).once

      subject.sign_certificate(  )
    end
  end

  describe '#with_puppet_running_on' do
    let(:test_case_path) { 'testcase/path' }
    let(:tmpdir_path) { '/tmp/tmpdir' }
    let(:is_pe) { false }
    let(:use_service) { false }
    let(:platform) { 'redhat' }
    let(:host) {
      FakeHost.create('fakevm', "#{platform}-version-arch",
        'type' => is_pe ? 'pe': 'git',
        'use-service' => use_service
      )
    }

    def stub_host_and_subject_to_allow_the_default_testdir_argument_to_be_created
      subject.instance_variable_set(:@path, test_case_path)
      allow( host ).to receive(:tmpdir).and_return(tmpdir_path)
      allow( host ).to receive(:file_exist?).and_return(true)
      allow( subject ).to receive( :options ).and_return( {} )
    end

    before do
      stub_host_and_subject_to_allow_the_default_testdir_argument_to_be_created
      allow( subject ).to receive(:curl_with_retries)
    end

    it "raises an ArgumentError if you try to submit a String instead of a Hash of options" do
      expect { subject.with_puppet_running_on(host, '--foo --bar') }.to raise_error(ArgumentError, /conf_opts must be a Hash. You provided a String: '--foo --bar'/)
    end

    it 'raises the early_exception if backup_the_file fails' do
      allow( host ).to receive( :use_service_scripts? )
      allow( subject ).to receive( :restore_puppet_conf_from_backup )
      expect( subject ).to receive(:backup_the_file).and_raise(RuntimeError.new('puppet conf backup failed'))
      expect {
        subject.with_puppet_running_on(host, {})
      }.to raise_error(RuntimeError, /puppet conf backup failed/)
    end

    it 'receives a Minitest::Assertion and fails the test correctly' do
      allow( subject ).to receive( :backup_the_file ).and_raise( Minitest::Assertion.new('assertion failed!') )
      allow( host ).to receive( :puppet ).and_return( {} )
      allow( subject ).to receive( :restore_puppet_conf_from_backup )
      allow( host ).to receive( :use_service_scripts? )
      expect( subject ).to receive( :fail_test )
      subject.with_puppet_running_on(host, {})
    end

    context 'with test flow exceptions' do
      it 'can pass_test' do
        expect( subject ).to receive(:backup_the_file).and_raise(Beaker::DSL::Outcomes::PassTest)
        expect {
          subject.with_puppet_running_on(host, {}).to receive(:pass_test)
        }.to raise_error(Beaker::DSL::Outcomes::PassTest)
      end
      it 'can fail_test' do
        expect( subject ).to receive(:backup_the_file).and_raise(Beaker::DSL::Outcomes::FailTest)
        expect {
          subject.with_puppet_running_on(host, {}).to receive(:fail_test)
        }.to raise_error(Beaker::DSL::Outcomes::FailTest)
      end
      it 'can skip_test' do
        expect( subject ).to receive(:backup_the_file).and_raise(Beaker::DSL::Outcomes::SkipTest)
        expect {
          subject.with_puppet_running_on(host, {}).to receive(:skip_test)
        }.to raise_error(Beaker::DSL::Outcomes::SkipTest)
      end
      it 'can pending_test' do
        expect( subject ).to receive(:backup_the_file).and_raise(Beaker::DSL::Outcomes::PendingTest)
        expect {
          subject.with_puppet_running_on(host, {}).to receive(:pending_test)
        }.to raise_error(Beaker::DSL::Outcomes::PendingTest)
      end
    end

    describe 'with puppet-server' do
      let(:default_confdir) { "/etc/puppet" }
      let(:default_vardir) { "/var/lib/puppet" }

      let(:custom_confdir) { "/tmp/etc/puppet" }
      let(:custom_vardir) { "/tmp/var/lib/puppet" }

      let(:command_line_args) {"--vardir=#{custom_vardir} --confdir=#{custom_confdir}"}
      let(:conf_opts) { {:__commandline_args__ => command_line_args,
                         :is_puppetserver => true}}

      let(:default_puppetserver_opts) {
        { "jruby-puppet" => {
            "master-conf-dir" => default_confdir,
            "master-var-dir" => default_vardir,
          },
          "certificate-authority" => {
            "allow-subject-alt-names" => true,
          }
        }
      }

      let(:custom_puppetserver_opts) {
        { "jruby-puppet" => {
            "master-conf-dir" => custom_confdir,
            "master-var-dir" => custom_vardir,
          },
          "certificate-authority" => {
            "allow-subject-alt-names" => true,
          }
        }
      }

      let(:puppetserver_conf) { "/etc/puppetserver/conf.d/puppetserver.conf" }
      let(:logger) { double }

      def stub_post_setup
        allow( subject ).to receive( :restore_puppet_conf_from_backup)
        allow( subject ).to receive( :bounce_service)
        allow( subject ).to receive( :stop_puppet_from_source_on)
        allow( subject ).to receive( :dump_puppet_log)
        allow( subject ).to receive( :restore_puppet_conf_from_backup)
        allow( subject ).to receive( :puppet_master_started)
        allow( subject ).to receive( :start_puppet_from_source_on!)
        allow( subject ).to receive( :lay_down_new_puppet_conf)
        allow( subject ).to receive( :logger) .and_return( logger )
        allow( logger ).to receive( :error)
        allow( logger ).to receive( :debug)
      end

      before do
        stub_post_setup
        allow( subject ).to receive(:options).and_return({:is_puppetserver => true})
        allow( subject ).to receive(:modify_tk_config)
        allow( subject ).to receive(:puppet_config).with(host, 'confdir', anything).and_return(default_confdir)
        allow( subject ).to receive(:puppet_config).with(host, 'vardir', anything).and_return(default_vardir)
        allow( subject ).to receive(:puppet_config).with(host, 'config', anything).and_return("#{default_confdir}/puppet.conf")
      end

      describe 'when the global option for :is_puppetserver is false' do
        it 'checks the option for the host object' do
          allow( subject ).to receive( :options) .and_return( {:is_puppetserver => false})
          host[:is_puppetserver] = true
          expect(subject).to receive(:modify_tk_config)
          subject.with_puppet_running_on(host, conf_opts)
        end
      end

      describe 'and command line args passed' do
        it 'modifies SUT trapperkeeper configuration w/ command line args' do
          host['puppetserver-confdir'] = '/etc/puppetserver/conf.d'
          expect( subject ).to receive( :modify_tk_config).with(host, puppetserver_conf,
                                                          custom_puppetserver_opts)
          subject.with_puppet_running_on(host, conf_opts)
        end
      end

      describe 'and no command line args passed' do
        let(:command_line_args) { nil }
        it 'modifies SUT trapperkeeper configuration w/ puppet defaults' do
          host['puppetserver-confdir'] = '/etc/puppetserver/conf.d'
          expect( subject ).to receive( :modify_tk_config).with(host, puppetserver_conf,
                                                          default_puppetserver_opts)
          subject.with_puppet_running_on(host, conf_opts)
        end
      end
    end

    describe "with valid arguments" do
      before do
        expect( Tempfile ).to receive(:open).with('beaker')
      end

      context 'for pe hosts' do
        let(:is_pe) { true }
        let(:service_restart) { true }

        it 'bounces puppet twice' do
          subject.with_puppet_running_on(host, {})
          expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=running/).exactly(2).times
          expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=stopped/).exactly(2).times
        end

        it 'yields to a block in between bouncing service calls' do
          execution = 0
          allow( subject ).to receive(:curl_with_retries)
          expect do
            subject.with_puppet_running_on(host, {}) do
              expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=running/).exactly(1).times
              expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=stopped/).exactly(1).times
              execution += 1
            end
          end.to change { execution }.by(1)
          expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=running/).exactly(2).times
          expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=stopped/).exactly(2).times
        end

        context ':restart_when_done flag set false' do
          it 'starts puppet once, stops it twice' do
            subject.with_puppet_running_on(host, { :restart_when_done => false })
            expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=running/).once
            expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=stopped/).exactly(2).times
          end

          it 'can be set globally in options' do
            host[:restart_when_done] = false

            subject.with_puppet_running_on(host, {})

            expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=running/).once
            expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=stopped/).exactly(2).times
          end

          it 'yields to a block after bouncing service' do
            execution = 0
            allow( subject ).to receive(:curl_with_retries)
            expect do
              subject.with_puppet_running_on(host, { :restart_when_done => false }) do
                expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=running/).exactly(1).times
                expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=stopped/).exactly(1).times
                execution += 1
              end
            end.to change { execution }.by(1)
            expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=stopped/).exactly(2).times
          end
        end
      end

      context 'for foss packaged hosts using passenger' do
        before(:each) do
          host.uses_passenger!
        end
        it 'bounces puppet twice' do
          allow( subject ).to receive(:curl_with_retries)
          subject.with_puppet_running_on(host, {})
          expect(host).to execute_commands_matching(/apachectl graceful/).exactly(2).times
        end

        it 'gracefully restarts using apache2ctl' do
          allow(host).to receive( :check_for_command ).and_return( true )
          allow( subject ).to receive(:curl_with_retries)
          subject.with_puppet_running_on(host, {})
          expect(host).to execute_commands_matching(/apache2ctl graceful/).exactly(2).times
        end

        it 'gracefully restarts using apachectl' do
          allow(host).to receive( :check_for_command ).and_return( false )
          allow( subject ).to receive(:curl_with_retries)
          subject.with_puppet_running_on(host, {})
          expect(host).to execute_commands_matching(/apachectl graceful/).exactly(2).times
        end

        it 'yields to a block after bouncing service' do
          execution = 0
          allow( subject ).to receive(:curl_with_retries)
          expect do
            subject.with_puppet_running_on(host, {}) do
              expect(host).to execute_commands_matching(/apachectl graceful/).once
              execution += 1
            end
          end.to change { execution }.by(1)
          expect(host).to execute_commands_matching(/apachectl graceful/).exactly(2).times
        end

        context ':restart_when_done flag set false' do
          it 'bounces puppet once' do
            allow( subject ).to receive(:curl_with_retries)
            subject.with_puppet_running_on(host, { :restart_when_done => false })
            expect(host).to execute_commands_matching(/apachectl graceful/).once
          end

          it 'yields to a block after bouncing service' do
            execution = 0
            allow( subject ).to receive(:curl_with_retries)
            expect do
              subject.with_puppet_running_on(host, { :restart_when_done => false }) do
                expect(host).to execute_commands_matching(/apachectl graceful/).once
                execution += 1
              end
            end.to change { execution }.by(1)
          end
        end
      end

      context 'for foss packaged hosts using webrick' do
        let(:use_service) { true }

        it 'stops and starts master using service scripts twice' do
          allow( subject ).to receive(:curl_with_retries)
          subject.with_puppet_running_on(host, {})
          expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=running/).exactly(2).times
          expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=stopped/).exactly(2).times
        end

        it 'yields to a block in between bounce calls for the service' do
          execution = 0
          expect do
            subject.with_puppet_running_on(host, {}) do
              expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=running/).once
              expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=stopped/).once
              execution += 1
            end
          end.to change { execution }.by(1)
          expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=running/).exactly(2).times
          expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=stopped/).exactly(2).times
        end

        context ':restart_when_done flag set false' do
          it 'stops (twice) and starts (once) master using service scripts' do
            allow( subject ).to receive(:curl_with_retries)
            subject.with_puppet_running_on(host, { :restart_when_done => false })
            expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=running/).once
            expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=stopped/).exactly(2).times
          end

          it 'yields to a block after stopping and starting service' do
            execution = 0
            expect do
              subject.with_puppet_running_on(host, { :restart_when_done => false }) do
                expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=running/).once
                expect(host).to execute_commands_matching(/puppet resource service #{host['puppetservice']}.*ensure=stopped/).once
                execution += 1
              end
            end.to change { execution }.by(1)
          end
        end
      end

      context 'running from source' do
        let('use-service') { false }

        it 'does not try to stop if not started' do
          expect( subject ).to receive(:start_puppet_from_source_on!).and_return false
          expect( subject ).to_not receive(:stop_puppet_from_source_on)

          subject.with_puppet_running_on(host, {})
        end

        context 'successfully' do
          before do
            expect( host ).to receive(:port_open?).with(8140).and_return(true)
          end

          it 'starts puppet from source' do
            subject.with_puppet_running_on(host, {})
          end

          it 'stops puppet from source' do
            subject.with_puppet_running_on(host, {})
            expect(host).to execute_commands_matching(/^kill [^-]/).once
            expect(host).to execute_commands_matching(/^kill -0/).once
          end

          it 'yields between starting and stopping' do
            execution = 0
            expect do
              subject.with_puppet_running_on(host, {}) do
                expect(host).to execute_commands_matching(/^puppet master/).once
                execution += 1
              end
            end.to change { execution }.by(1)
            expect(host).to execute_commands_matching(/^kill [^-]/).once
            expect(host).to execute_commands_matching(/^kill -0/).once
          end

          it 'passes on commandline args' do
            subject.with_puppet_running_on(host, {:__commandline_args__ => '--with arg'})
            expect(host).to execute_commands_matching(/^puppet master --with arg/).once
          end

          it 'is not affected by the :restart_when_done flag' do
            execution = 0
            expect do
              subject.with_puppet_running_on(host, { :restart_when_done => true }) do
                expect(host).to execute_commands_matching(/^puppet master/).once
                execution += 1
              end
            end.to change { execution }.by(1)
            expect(host).to execute_commands_matching(/^kill [^-]/).once
            expect(host).to execute_commands_matching(/^kill -0/).once
          end
        end
      end

      describe 'backup and restore of puppet.conf' do
        before :each do
          allow(subject).to receive(:puppet_config).with(host, 'confdir', anything).and_return('/root/mock')
          allow(subject).to receive(:puppet_config).with(host, 'config', anything).and_return('/root/mock/puppet.conf')
        end

        let(:original_location) { '/root/mock/puppet.conf' }
        let(:backup_location) {
          filename = File.basename(original_location)
          File.join(tmpdir_path, "#{filename}.bak")
        }
        let(:new_location) {
          filename = File.basename(original_location)
          File.join(tmpdir_path, filename)
        }

        context 'when a puppetservice is used' do
          let(:use_service) { true }

          it 'backs up puppet.conf' do
            subject.with_puppet_running_on(host, {})
            expect(host).to execute_commands_matching(/cp #{original_location} #{backup_location}/).once
            expect(host).to execute_commands_matching(/cat #{new_location} > #{original_location}/).once
          end

          it 'restores puppet.conf before restarting' do
            subject.with_puppet_running_on(host, { :restart_when_done => true })
            expect(host).to execute_commands_matching_in_order(/cat '#{backup_location}' > '#{original_location}'/,
                                                               /ensure=stopped/,
                                                               /ensure=running/)
          end
        end

        context 'when a puppetservice is not used' do
          before do
            expect( host ).to receive(:port_open?).with(8140).and_return(true)
          end

          it 'backs up puppet.conf' do
            subject.with_puppet_running_on(host, {})
            expect(host).to execute_commands_matching(/cp #{original_location} #{backup_location}/).once
            expect(host).to execute_commands_matching(/cat #{new_location} > #{original_location}/).once
          end

          it 'restores puppet.conf after restarting when a puppetservice is not used' do
            subject.with_puppet_running_on(host, {})
            expect(host).to execute_commands_matching_in_order(/kill [^-]/,
                                                               /cat '#{backup_location}' > '#{original_location}'/m)
          end

          it "doesn't restore a non-existent file" do
            allow( subject ).to receive(:backup_the_file)
            subject.with_puppet_running_on(host, {})
            expect(host).to execute_commands_matching(/rm -f '#{original_location}'/)
          end
        end
      end

      let(:logger) { double.as_null_object }
      describe 'handling failures' do

        before do
          allow( subject ).to receive( :logger ).and_return( logger )
          expect( subject ).to receive(:stop_puppet_from_source_on).and_raise(RuntimeError.new('Also failed in teardown.'))
          expect( host ).to receive(:port_open?).with(8140).and_return(true)
        end

        it 'does not swallow an exception raised from within test block if ensure block also fails' do
          expect( subject.logger ).to receive(:error).with(/Raised during attempt to teardown.*Also failed in teardown/)

          expect do
            subject.with_puppet_running_on(host, {}) { raise 'Failed while yielding.' }
          end.to raise_error(RuntimeError, /failed.*because.*Failed while yielding./)
        end

        it 'dumps the puppet logs if there is an error in the teardown' do
          expect( subject.logger ).to receive(:notify).with(/Dumping master log/)

          expect do
            subject.with_puppet_running_on(host, {})
          end.to raise_error(RuntimeError, /Also failed in teardown/)
        end

        it 'does not mask the teardown error with an error from dumping the logs' do
          expect( subject.logger ).to receive(:notify).with(/Dumping master log/).and_raise("Error from dumping logs")

          expect do
            subject.with_puppet_running_on(host, {})
          end.to raise_error(RuntimeError, /Also failed in teardown/)
        end

        it 'does not swallow a teardown exception if no earlier exception was raised' do
          expect( subject.logger).to_not receive(:error)
          expect do
            subject.with_puppet_running_on(host, {})
          end.to raise_error(RuntimeError, 'Also failed in teardown.')
        end

      end

    end
  end

  describe '#with_puppet_running' do
    it 'delegates to #with_puppet_running_on with the default host' do
      allow( subject ).to receive( :hosts ).and_return( hosts )
      expect( subject ).to receive( :default ).and_return( master )

      expect( subject ).to receive( :with_puppet_running_on ).with( master, {:opt => 'value'}, '/dir' ).once

      subject.with_puppet_running( {:opt => 'value'}, '/dir' )


    end
  end

  describe '#bounce_service' do
    let( :options ) { Beaker::Options::Presets.new.presets }
    let( :result ) { double.as_null_object }
    before :each do
      allow( subject ).to receive( :options ) { options }
    end

    it 'requests a reload but not a restart if the reload is successful' do
      host = FakeHost.create
      allow( result ).to receive( :exit_code ).and_return( 0 )
      allow( host ).to receive( :any_exec_result ).and_return( result )
      allow( host ).to receive( :graceful_restarts? ).and_return( false )

      expect( Beaker::Command ).to receive( :new ).with(
        /service not_real_service reload/
      ).once
      expect( subject ).to receive( :puppet_resource ).never
      subject.bounce_service( host, 'not_real_service')
    end

    it 'requests a restart if the reload fails' do
      host = FakeHost.create
      allow( result ).to receive( :exit_code ).and_return( 1 )
      allow( host ).to receive( :exec ).and_return( result )
      expect( subject ).to receive( :curl_with_retries )
      expect( subject ).to receive( :puppet_resource ).with(
        anything, 'not_real_service', anything
      ).exactly( 2 ).times
      subject.bounce_service( host, 'not_real_service' )
    end

    it 'uses the default port argument if none given' do
      host = FakeHost.create
      expect( host ).to receive( :graceful_restarts? ).and_return( false )
      allow( result ).to receive( :exit_code ).and_return( 1 )
      expect( subject ).to receive( :curl_with_retries ).with(
        anything, anything, /8140/, anything, anything
      )
      subject.bounce_service( host, 'not_real_service')
    end

    it 'takes the port argument' do
      host = FakeHost.create
      expect( host ).to receive( :graceful_restarts? ).and_return( false )
      allow( result ).to receive( :exit_code ).and_return( 1 )
      expect( subject ).to receive( :curl_with_retries ).with(
        anything, anything, /8000/, anything, anything
      )
      subject.bounce_service( host, 'not_real_service', nil, 8000)
    end
  end

  describe '#sleep_until_puppetdb_started' do
    let( :options ) do # defaults from presets.rb
      {
        :puppetdb_port_nonssl => 8080,
        :puppetdb_port_ssl => 8081
      }
    end

    before :each do
      allow( subject ).to receive( :options ) { options }
      allow( hosts[0] ).to receive( :node_name ).and_return( '' )
      allow( subject ).to receive( :version_is_less ).and_return( true )
    end

    it 'uses the default ports if none given' do
      host = hosts[0]
      expect( subject ).to receive( :retry_on ).with( anything(), /8080/, anything() ).once.ordered
      expect( subject ).to receive( :curl_with_retries ).with( anything(), anything(), /8081/, anything() ).once.ordered
      subject.sleep_until_puppetdb_started( host )
    end

    it 'allows setting the nonssl_port' do
      host = hosts[0]
      expect( subject ).to receive( :retry_on ).with( anything(), /8084/, anything() ).once.ordered
      expect( subject ).to receive( :curl_with_retries ).with( anything(), anything(), /8081/, anything() ).once.ordered

      subject.sleep_until_puppetdb_started( host, 8084 )
    end

    it 'allows setting the ssl_port' do
      host = hosts[0]
      expect( subject ).to receive( :retry_on ).with( anything(), /8080/, anything() ).once.ordered
      expect( subject ).to receive( :curl_with_retries ).with( anything(), anything(), /8085/, anything() ).once.ordered

      subject.sleep_until_puppetdb_started( host, nil, 8085 )
    end

    context 'when pe_ver is less than 2016.1.0' do
      it 'uses the version endpoint' do
        host = hosts[0]
        host['pe_ver'] = '2015.3.3'
        expect( subject ).to receive( :retry_on ).with( anything(), /pdb\/meta\/v1\/version/, anything() ).once.ordered
        expect( subject ).to receive( :curl_with_retries ).with( anything(), anything(), /8081/, anything() ).once.ordered

        expect( subject ).to receive( :version_is_less ).with( host['pe_ver'], '2016.1.0' ).and_return( true )
        subject.sleep_until_puppetdb_started( host )
      end
    end

    context 'when pe_ver is greater than 2015.9.9' do
      it 'uses the status endpoint' do
        host = hosts[0]
        host['pe_ver'] = '2016.1.0'
        expect( subject ).to receive( :retry_on ).with( anything(), /status\/v1\/services\/puppetdb-status/, anything() ).once.ordered
        expect( subject ).to receive( :curl_with_retries ).with( anything(), anything(), /8081/, anything() ).once.ordered

        expect( subject ).to receive( :version_is_less ).with( host['pe_ver'], '2016.1.0' ).and_return( false )
        subject.sleep_until_puppetdb_started( host )
      end
    end

  end

  describe '#sleep_until_puppetserver_started' do
    let( :options ) do
      { :puppetserver_port => 8140 }
    end

    before :each do
      allow( subject ).to receive( :options ) { options }
      allow( hosts[0] ).to receive( :node_name )
    end

    it 'uses the default port if none given' do
      host = hosts[0]
      expect( subject ).to receive( :curl_with_retries ).with( anything(), anything(), /8140/, anything() ).once.ordered
      subject.sleep_until_puppetserver_started( host )
    end

    it 'allows setting the port' do
      host = hosts[0]
      expect( subject ).to receive( :curl_with_retries ).with( anything(), anything(), /8147/, anything() ).once.ordered
      subject.sleep_until_puppetserver_started( host, 8147 )
    end
  end

  describe '#sleep_until_nc_started' do
    let( :options ) do # defaults from presets.rb
      { :nodeclassifier_port => 4433 }
    end

    before :each do
      allow( subject ).to receive( :options ) { options }
      allow( hosts[0] ).to receive( :node_name )
    end

    it 'uses the default port if none given' do
      host = hosts[0]
      expect( subject ).to receive( :curl_with_retries ).with( anything(), anything(), /4433/, anything() ).once.ordered
      subject.sleep_until_nc_started( host )
    end

    it 'allows setting the port' do
      host = hosts[0]
      expect( subject ).to receive( :curl_with_retries ).with( anything(), anything(), /4435/, anything() ).once.ordered
      subject.sleep_until_nc_started( host, 4435 )
    end
  end

end
