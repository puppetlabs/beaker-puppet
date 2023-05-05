require 'spec_helper'

class ClassMixedWithDSLInstallUtils
  include Beaker::DSL::InstallUtils
  include Beaker::DSL::InstallUtils::FOSSUtils
  include Beaker::DSL::Wrappers
  include Beaker::DSL::Helpers
  include Beaker::DSL::Structure
  include Beaker::DSL::Roles
  include Beaker::DSL::Patterns

  def logger
    @logger ||= RSpec::Mocks::Double.new('logger').as_null_object
  end
end

describe ClassMixedWithDSLInstallUtils do
  let(:metadata)      { @metadata ||= {} }
  let(:presets)       { Beaker::Options::Presets.new }
  let(:opts)          { presets.presets.merge(presets.env_vars).merge({ :type => 'foss' }) }
  let(:basic_hosts)   { make_hosts( { :pe_ver => '3.0',
                                      :platform => 'linux',
                                      :roles => [ 'agent' ],
                                      :type  => 'foss' }, 4 ) }
  let(:hosts)         { basic_hosts[0][:roles] = ['master', 'database', 'dashboard']
                        basic_hosts[1][:platform] = 'windows'
                        basic_hosts[2][:platform] = 'osx-10.9-x86_64'
                        basic_hosts[3][:platform] = 'eos'
                        basic_hosts  }
  let(:hosts_sorted)  { [ hosts[1], hosts[0], hosts[2], hosts[3] ] }
  let(:winhost)       { make_host( 'winhost', { :platform => Beaker::Platform.new('windows-2008r2-64'),
                                                :pe_ver => '3.0',
                                                :working_dir => '/tmp',
                                                :type => 'foss',
                                                :is_cygwin => true} ) }
  let(:winhost_non_cygwin) { make_host( 'winhost_non_cygwin', { :platform => 'windows',
                                                :pe_ver => '3.0',
                                                :working_dir => '/tmp',
                                                :type => 'foss',
                                                :is_cygwin => 'false' } ) }

  let(:machost)       { make_host( 'machost', { :platform => 'osx-10.9-x86_64',
                                                :pe_ver => '3.0',
                                                :type => 'foss',
                                                :working_dir => '/tmp' } ) }
  let(:freebsdhost12)   { make_host( 'freebsdhost12', { :platform => 'freebsd-12-amd64',
                                                :pe_ver => '3.0',
                                                :working_dir => '/tmp' } ) }
  let(:freebsdhost13)   { make_host( 'freebsdhost13', { :platform => 'freebsd-13-amd64',
                                                :pe_ver => '3.0',
                                                :working_dir => '/tmp' } ) }
  let(:unixhost)      { make_host( 'unixhost', { :platform => 'linux',
                                                 :pe_ver => '3.0',
                                                 :working_dir => '/tmp',
                                                :type => 'foss',
                                                 :dist => 'puppet-enterprise-3.1.0-rc0-230-g36c9e5c-debian-7-i386' } ) }
  let(:eoshost)       { make_host( 'eoshost', { :platform => 'eos',
                                                :pe_ver => '3.0',
                                                :working_dir => '/tmp',
                                                :type => 'foss',
                                                :dist => 'puppet-enterprise-3.7.1-rc0-78-gffc958f-eos-4-i386' } ) }
  let(:el6hostaio)    { make_host( 'el6hostaio', { :platform => Beaker::Platform.new('el-6-i386'),
                                                 :pe_ver => '3.0',
                                                 :working_dir => '/tmp',
                                                :type => 'aio',
                                                 :dist => 'puppet-enterprise-3.1.0-rc0-230-g36c9e5c-centos-6-i386' } ) }
  let(:el6hostfoss)   { make_host( 'el6hostfoss', { :platform => Beaker::Platform.new('el-6-i386'),
                                                 :pe_ver => '3.0',
                                                 :working_dir => '/tmp',
                                                :type => 'foss',
                                                 :dist => 'puppet-enterprise-3.1.0-rc0-230-g36c9e5c-centos-6-i386' } ) }

  let(:win_temp)      { 'C:\\Windows\\Temp' }

  context '#sanitize_opts' do
    let(:opts) {
      {
        :win_download_url => nil,
        :dev_builds_url => '',
        :release_yum_repo_url => 'https://apt.customserver.net/apt'
      }
    }

    it 'honors any custom values' do
      expect( subject.sanitize_opts(opts)).to include({release_yum_repo_url: 'https://apt.customserver.net/apt'})
    end

    it 'overwrites any nil values with pre-defined defaults' do
      default_win_url = described_class::FOSS_DEFAULT_DOWNLOAD_URLS[:win_download_url]
      expect( subject.sanitize_opts(opts)).to include({win_download_url: default_win_url})
    end

    it 'keeps empty strings' do
      expect( subject.sanitize_opts(opts)).to include({dev_builds_url: ''})
    end

    it 'adds any undefined defaults' do
      default_mac_url = described_class::FOSS_DEFAULT_DOWNLOAD_URLS[:mac_download_url]
      expect( subject.sanitize_opts(opts)).to include({mac_download_url: default_mac_url})
    end
  end


  context '#configure_foss_defaults_on' do
    it 'uses aio paths for hosts with role aio' do
      hosts.each do |host|
        host[:pe_ver] = nil
        host[:version] = nil
        host[:roles] = host[:roles] | ['aio']
      end
      expect(subject).to receive(:add_foss_defaults_on).exactly(hosts.length).times
      expect(subject).to receive(:add_aio_defaults_on).exactly(hosts.length).times
      expect(subject).to receive(:add_puppet_paths_on).exactly(hosts.length).times

      subject.configure_foss_defaults_on( hosts )
    end

    it 'uses no paths for hosts with no type' do
      hosts.each do |host|
        host[:type] = nil
      end
      expect(subject).to receive(:add_aio_defaults_on).never
      expect(subject).to receive(:add_foss_defaults_on).never
      expect(subject).to receive(:add_puppet_paths_on).never

      subject.configure_foss_defaults_on( hosts )
    end

    it 'uses aio paths for hosts with aio type (backwards compatability)' do
      hosts.each do |host|
        host[:pe_ver] = nil
        host[:version] = nil
        host[:type] = 'aio'
      end
      expect(subject).to receive(:add_aio_defaults_on).exactly(hosts.length).times
      expect(subject).to receive(:add_foss_defaults_on).never
      expect(subject).to receive(:add_puppet_paths_on).exactly(hosts.length).times

      subject.configure_foss_defaults_on( hosts )
    end

    it 'uses aio paths for hosts of version >= 4.0' do
      hosts.each do |host|
        host[:version] = '4.0'
        host[:pe_ver] = nil
        host[:roles] = host[:roles] - ['aio']
      end
      expect(subject).to receive(:add_aio_defaults_on).exactly(hosts.length).times
      expect(subject).to receive(:add_foss_defaults_on).exactly(hosts.length).times
      expect(subject).to receive(:add_puppet_paths_on).exactly(hosts.length).times

      subject.configure_foss_defaults_on( hosts )
    end

    it 'uses foss paths for hosts of version < 4.0' do
      hosts.each do |host|
        host[:version] = '3.8'
        host[:pe_ver] = nil
      end
      expect(subject).to receive(:add_foss_defaults_on).exactly(hosts.length).times
      expect(subject).to receive(:add_aio_defaults_on).never
      expect(subject).to receive(:add_puppet_paths_on).exactly(hosts.length).times

      subject.configure_foss_defaults_on( hosts )
    end

    it 'uses foss paths for foss-like type foss-package' do
      hosts.each do |host|
        host[:type] = 'foss-package'
        host[:version] = '3.8'
        host[:pe_ver] = nil
      end
      expect(subject).to receive(:add_foss_defaults_on).exactly(hosts.length).times
      expect(subject).to receive(:add_aio_defaults_on).never
      expect(subject).to receive(:add_puppet_paths_on).exactly(hosts.length).times

      subject.configure_foss_defaults_on( hosts )
    end

  end

  context 'lookup_in_env' do
    it 'returns a default properly' do
      env_var = subject.lookup_in_env('noway', 'nonesuch', 'returnme')
      expect(env_var).to be == 'returnme'
      env_var = subject.lookup_in_env('noway', nil, 'returnme')
      expect(env_var).to be == 'returnme'
    end
    it 'finds correct env variable' do
      allow(ENV).to receive(:[]).with(nil).and_return(nil)
      allow(ENV).to receive(:[]).with('REALLYNONE').and_return(nil)
      allow(ENV).to receive(:[]).with('NONESUCH').and_return('present')
      allow(ENV).to receive(:[]).with('NOWAY_PROJ_NONESUCH').and_return('exists')
      env_var = subject.lookup_in_env('nonesuch', 'noway-proj', 'fail')
      expect(env_var).to be == 'exists'
      env_var = subject.lookup_in_env('nonesuch')
      expect(env_var).to be == 'present'
      env_var = subject.lookup_in_env('reallynone')
      expect(env_var).to be == nil
      env_var = subject.lookup_in_env('reallynone',nil,'default')
      expect(env_var).to be == 'default'
    end
  end

  context 'build_giturl' do
    it 'returns urls properly' do
      allow(ENV).to receive(:[]).with('SERVER').and_return(nil)
      allow(ENV).to receive(:[]).with('FORK').and_return(nil)
      allow(ENV).to receive(:[]).with('PUPPET_FORK').and_return(nil)
      allow(ENV).to receive(:[]).with('PUPPET_SERVER').and_return(nil)
      url = subject.build_giturl('puppet')
      expect(url).to be == 'https://github.com/puppetlabs/puppet.git'
      url = subject.build_giturl('puppet', 'er0ck')
      expect(url).to be == 'https://github.com/er0ck/puppet.git'
      url = subject.build_giturl('puppet', 'er0ck', 'bitbucket.com')
      expect(url).to be == 'https://bitbucket.com/er0ck-puppet.git'
      url = subject.build_giturl('puppet', 'er0ck', 'github.com', 'https://')
      expect(url).to be == 'https://github.com/er0ck/puppet.git'
      url = subject.build_giturl('puppet', 'er0ck', 'github.com', 'https')
      expect(url).to be == 'https://github.com/er0ck/puppet.git'
      url = subject.build_giturl('puppet', 'er0ck', 'github.com', 'git@')
      expect(url).to be == 'git@github.com:er0ck/puppet.git'
      url = subject.build_giturl('puppet', 'er0ck', 'github.com', 'git')
      expect(url).to be == 'git@github.com:er0ck/puppet.git'
      url = subject.build_giturl('puppet', 'er0ck', 'github.com', 'ssh')
      expect(url).to be == 'git@github.com:er0ck/puppet.git'
    end

    it 'uses ENV to build urls properly' do
      allow(ENV).to receive(:[]).with('SERVER').and_return(nil)
      allow(ENV).to receive(:[]).with('FORK').and_return(nil)
      allow(ENV).to receive(:[]).with('PUPPET_FORK').and_return('er0ck/repo')
      allow(ENV).to receive(:[]).with('PUPPET_SERVER').and_return('gitlab.com')
      url = subject.build_giturl('puppet')
      expect(url).to be == 'https://gitlab.com/er0ck/repo-puppet.git'
      url = subject.build_giturl('puppet', 'er0ck')
      expect(url).to be == 'https://gitlab.com/er0ck-puppet.git'
      url = subject.build_giturl('puppet', 'er0ck', 'bitbucket.com')
      expect(url).to be == 'https://bitbucket.com/er0ck-puppet.git'
      url = subject.build_giturl('puppet', 'er0ck', 'github.com', 'https://')
      expect(url).to be == 'https://github.com/er0ck/puppet.git'
      url = subject.build_giturl('puppet', 'er0ck', 'github.com', 'https')
      expect(url).to be == 'https://github.com/er0ck/puppet.git'
      url = subject.build_giturl('puppet', 'er0ck', 'github.com', 'git@')
      expect(url).to be == 'git@github.com:er0ck/puppet.git'
      url = subject.build_giturl('puppet', 'er0ck', 'github.com', 'git')
      expect(url).to be == 'git@github.com:er0ck/puppet.git'
      url = subject.build_giturl('puppet', 'er0ck', 'github.com', 'ssh')
      expect(url).to be == 'git@github.com:er0ck/puppet.git'
    end
  end

  context 'extract_repo_info_from' do
    [{ :protocol => 'git', :path => 'git://github.com/puppetlabs/project.git' },
     { :protocol => 'ssh', :path => 'git@github.com:puppetlabs/project.git' },
     { :protocol => 'https', :path => 'https://github.com:puppetlabs/project' },
     { :protocol => 'file', :path => 'file:///home/example/project' }
    ].each do |type|
      it "handles #{ type[:protocol] } uris" do
        uri = "#{ type[:path] }#master"
        repo_info = subject.extract_repo_info_from uri
        expect( repo_info[:name] ).to be == 'project'
        expect( repo_info[:path] ).to be ==  type[:path]
        expect( repo_info[:rev] ).to  be == 'master'
      end
    end
  end

  context 'order_packages' do
    it 'orders facter, hiera before puppet, before anything else' do
      named_repos = [
        { :name => 'puppet_plugin' }, { :name => 'puppet' }, { :name => 'facter' }
      ]
      ordered_repos = subject.order_packages named_repos
      expect( ordered_repos[0][:name] ).to be == 'facter'
      expect( ordered_repos[1][:name] ).to be == 'puppet'
      expect( ordered_repos[2][:name] ).to be == 'puppet_plugin'
    end
  end

  context 'find_git_repo_versions' do
    it 'returns a hash of :name => version' do
      host        = double( 'Host' )
      repository  = { :name => 'name' }
      path        = '/path/to/repo'
      cmd         = 'cd /path/to/repo/name && git describe || true'
      logger = double.as_null_object

      allow( subject ).to receive( :metadata ).and_return( metadata )
      expect( subject ).to receive( :logger ).and_return( logger )
      expect( subject ).to receive( :on ).with( host, cmd ).and_yield
      expect( subject ).to receive( :stdout ).and_return( '2' )

      subject.instance_variable_set( :@metadata, {} )
      version = subject.find_git_repo_versions( host, path, repository )

      expect( version ).to be == { 'name' => '2' }
    end
  end

  context 'install_puppet_from_rpm_on' do
    it 'installs puppet release repo when set' do
      expect(subject).to receive(:install_puppetlabs_release_repo).with(el6hostaio,'puppet',{:puppet_collection => 'puppet'})

      subject.install_puppet_from_rpm_on( el6hostaio, {:puppet_collection => 'puppet'}  )
    end

    it 'installs PC1 release repo when AIO' do
      expect(subject).to receive(:install_puppetlabs_release_repo).with(el6hostaio,'pc1',{})

      subject.install_puppet_from_rpm_on( el6hostaio, {}  )
    end

    it 'installs non-PC1 package when not-AIO' do
      expect(subject).to receive(:install_puppetlabs_release_repo).with(el6hostfoss,nil,{})

      subject.install_puppet_from_rpm_on( el6hostfoss, {}  )
    end
  end

  context 'install_puppet_from_freebsd_ports_on' do
    it 'installs puppet on FreeBSD 12' do
      expect(freebsdhost12).to receive(:install_package).with('sysutils/puppet7')

      subject.install_puppet_from_freebsd_ports_on( freebsdhost12, {}  )
    end

    it 'installs puppet on FreeBSD 13' do
      expect(freebsdhost13).to receive(:install_package).with('sysutils/puppet7')

      subject.install_puppet_from_freebsd_ports_on( freebsdhost13, {}  )
    end
  end

  context 'install_puppet_from_msi' do
    before :each do
      [winhost, winhost_non_cygwin].each do |host|
        allow(host).to receive(:system_temp_path).and_return(win_temp)
      end
    end

    it 'installs puppet on cygwin windows' do
      allow(subject).to receive(:link_exists?).and_return( true )
      expect(subject).to receive(:on).with(winhost, "curl --location --output \"#{win_temp}\\puppet-3.7.1-x64.msi\" --remote-name http://downloads.puppet.com/windows/puppet-3.7.1-x64.msi")
      expect(subject).to receive(:on).with(winhost, " echo 'export PATH=$PATH:\"/cygdrive/c/Program Files (x86)/Puppet Labs/Puppet/bin\":\"/cygdrive/c/Program Files/Puppet Labs/Puppet/bin\"' > /etc/bash.bashrc ")
      expect(subject).to receive(:install_msi_on).with(winhost, "#{win_temp}\\puppet-3.7.1-x64.msi", {}, {:debug => nil})

      subject.install_puppet_from_msi( winhost, {:version => '3.7.1', :win_download_url => 'http://downloads.puppet.com/windows'}  )
    end

    it 'installs puppet on cygwin windows via proxy' do
      allow(subject).to receive(:link_exists?).and_return( true )
      expect(subject).to receive(:on).with(winhost, "curl -x https://proxy.com --location --output \"#{win_temp}\\puppet-3.7.1-x64.msi\" --remote-name http://downloads.puppet.com/windows/puppet-3.7.1-x64.msi")
      expect(subject).to receive(:on).with(winhost, " echo 'export PATH=$PATH:\"/cygdrive/c/Program Files (x86)/Puppet Labs/Puppet/bin\":\"/cygdrive/c/Program Files/Puppet Labs/Puppet/bin\"' > /etc/bash.bashrc ")
      expect(subject).to receive(:install_msi_on).with(winhost, "#{win_temp}\\puppet-3.7.1-x64.msi", {}, {:debug => nil})

      subject.install_puppet_from_msi( winhost, {:version => '3.7.1', :win_download_url => 'http://downloads.puppet.com/windows', :package_proxy => 'https://proxy.com'}  )
    end

    it 'installs puppet on non-cygwin windows' do
      allow(subject).to receive(:link_exists?).and_return( true )

      expect(winhost_non_cygwin).to receive(:mkdir_p).with('C:\\ProgramData\\PuppetLabs\\puppet\\etc\\modules')

      expect(subject).to receive(:on).with(winhost_non_cygwin, instance_of( Beaker::Command )) do |host, beaker_command|
        expect(beaker_command.command).to eq('powershell.exe')
        expect(beaker_command.args).to eq(["-ExecutionPolicy Bypass", "-InputFormat None", "-NoLogo", "-NoProfile", "-NonInteractive", "-Command $webclient = New-Object System.Net.WebClient; $webclient.DownloadFile('http://downloads.puppet.com/windows/puppet-3.7.1.msi','#{win_temp}\\puppet-3.7.1.msi')"])
      end.once

      expect(subject).to receive(:install_msi_on).with(winhost_non_cygwin, "#{win_temp}\\puppet-3.7.1.msi", {}, {:debug => nil})

      subject.install_puppet_from_msi( winhost_non_cygwin, {:version => '3.7.1', :win_download_url => 'http://downloads.puppet.com/windows'}   )
    end

    it 'installs puppet on non-cygwin windows via proxy' do
      allow(subject).to receive(:link_exists?).and_return( true )

      expect(winhost_non_cygwin).to receive(:mkdir_p).with('C:\\ProgramData\\PuppetLabs\\puppet\\etc\\modules')

      expect(subject).to receive(:on).with(winhost_non_cygwin, instance_of( Beaker::Command )) do |host, beaker_command|
        expect(beaker_command.command).to eq('powershell.exe')
        expect(beaker_command.args).to eq(["-ExecutionPolicy Bypass", "-InputFormat None", "-NoLogo", "-NoProfile", "-NonInteractive", "-Command $webclient = New-Object System.Net.WebClient; $webclient.Proxy = New-Object System.Net.WebProxy('https://proxy.com',$true); $webclient.DownloadFile('http://downloads.puppet.com/windows/puppet-3.7.1.msi','#{win_temp}\\puppet-3.7.1.msi')"])
      end.once

      expect(subject).to receive(:install_msi_on).with(winhost_non_cygwin, "#{win_temp}\\puppet-3.7.1.msi", {}, {:debug => nil})

      subject.install_puppet_from_msi( winhost_non_cygwin, {:version => '3.7.1', :win_download_url => 'http://downloads.puppet.com/windows', :package_proxy => 'https://proxy.com'})

    end
  end

  context 'clone_git_repo_on' do
    it 'does a ton of stuff it probably shouldnt' do
      repo = { :name => 'puppet',
               :path => 'git://my.server.net/puppet.git',
               :rev => 'master' }
      path = '/path/to/repos'
      host = { 'platform' => 'debian' }
      logger = double.as_null_object

      allow( subject ).to receive( :metadata ).and_return( metadata )
      allow( subject ).to receive( :configure_foss_defaults_on ).and_return( true )

      expect( subject ).to receive( :logger ).exactly( 2 ).times.and_return( logger )
      expect( subject ).to receive( :on ).exactly( 3 ).times

      subject.instance_variable_set( :@metadata, {} )
      subject.clone_git_repo_on( host, path, repo )
    end

    it 'allows a checkout depth of 1' do
      repo   = { :name => 'puppet',
                 :path => 'git://my.server.net/puppet.git',
                 :rev => 'master',
                 :depth => 1 }

      path   = '/path/to/repos'
      cmd    = "test -d #{path}/#{repo[:name]} || git clone --branch #{repo[:rev]} --depth #{repo[:depth]} #{repo[:path]} #{path}/#{repo[:name]}"
      host   = { 'platform' => 'debian' }
      logger = double.as_null_object
      allow( subject ).to receive( :metadata ).and_return( metadata )
      allow( subject ).to receive( :configure_foss_defaults_on ).and_return( true )
      expect( subject ).to receive( :logger ).exactly( 2 ).times.and_return( logger )
      expect( subject ).to receive( :on ).with( host, "test -d #{path} || mkdir -p #{path}", {:accept_all_exit_codes=>true} ).exactly( 1 ).times
      # this is the the command we want to test
      expect( subject ).to receive( :on ).with( host, cmd, {:accept_all_exit_codes=>true} ).exactly( 1 ).times
      expect( subject ).to receive( :on ).with( host, "cd #{path}/#{repo[:name]} && git remote rm origin && git remote add origin #{repo[:path]} && git fetch origin +refs/pull/*:refs/remotes/origin/pr/* +refs/heads/*:refs/remotes/origin/* && git clean -fdx && git checkout -f #{repo[:rev]}", {:accept_all_exit_codes=>true} ).exactly( 1 ).times

      subject.instance_variable_set( :@metadata, {} )
      subject.clone_git_repo_on( host, path, repo )
    end

    it 'allows a checkout depth with a rev from a specific branch' do
      repo   = { :name => 'puppet',
                 :path => 'git://my.server.net/puppet.git',
                 :rev => 'a2340acddadfeafd234230faf',
                 :depth => 50,
                 :depth_branch => 'master' }

      path   = '/path/to/repos'
      cmd    = "test -d #{path}/#{repo[:name]} || git clone --branch #{repo[:depth_branch]} --depth #{repo[:depth]} #{repo[:path]} #{path}/#{repo[:name]}"
      host   = { 'platform' => 'debian' }
      allow( subject ).to receive( :configure_foss_defaults_on ).and_return( true )
      logger = double.as_null_object
      allow( subject ).to receive( :metadata ).and_return( metadata )
      expect( subject ).to receive( :logger ).exactly( 2 ).times.and_return( logger )
      expect( subject ).to receive( :on ).with( host, "test -d #{path} || mkdir -p #{path}", {:accept_all_exit_codes=>true} ).exactly( 1 ).times
      # this is the the command we want to test
      expect( subject ).to receive( :on ).with( host, cmd, {:accept_all_exit_codes=>true} ).exactly( 1 ).times
      expect( subject ).to receive( :on ).with( host, "cd #{path}/#{repo[:name]} && git remote rm origin && git remote add origin #{repo[:path]} && git fetch origin +refs/pull/*:refs/remotes/origin/pr/* +refs/heads/*:refs/remotes/origin/* && git clean -fdx && git checkout -f #{repo[:rev]}", {:accept_all_exit_codes=>true} ).exactly( 1 ).times

      subject.instance_variable_set( :@metadata, {} )
      subject.clone_git_repo_on( host, path, repo )
    end
  end

  context 'install_from_git' do
    it 'does a ton of stuff it probably shouldnt' do
      repo = { :name => 'puppet',
               :path => 'git://my.server.net/puppet.git',
               :rev => 'master' }
      path = '/path/to/repos'
      host = { 'platform' => 'debian' }
      logger = double.as_null_object

      allow( subject ).to receive( :metadata ).and_return( metadata )
      allow( subject ).to receive( :configure_foss_defaults_on ).and_return( true )

      expect( subject ).to receive( :logger ).exactly( 3 ).times.and_return( logger )
      expect( subject ).to receive( :on ).exactly( 4 ).times

      subject.instance_variable_set( :@metadata, {} )
      subject.install_from_git( host, path, repo )
    end

    it 'should attempt to install ruby code' do
      repo   = { :name => 'puppet',
                 :path => 'git://my.server.net/puppet.git',
                 :rev => 'master',
                 :depth => 1 }

      path   = '/path/to/repos'
      cmd    = "test -d #{path}/#{repo[:name]} || git clone --branch #{repo[:rev]} --depth #{repo[:depth]} #{repo[:path]} #{path}/#{repo[:name]}"
      host   = { 'platform' => 'debian' }
      logger = double.as_null_object
      allow( subject ).to receive( :metadata ).and_return( metadata )
      allow( subject ).to receive( :configure_foss_defaults_on ).and_return( true )
      expect( subject ).to receive( :logger ).exactly( 3 ).times.and_return( logger )
      expect( subject ).to receive( :on ).with( host, "test -d #{path} || mkdir -p #{path}", {:accept_all_exit_codes=>true} ).exactly( 1 ).times
      expect( subject ).to receive( :on ).with( host, cmd, {:accept_all_exit_codes=>true} ).exactly( 1 ).times
      expect( subject ).to receive( :on ).with( host, "cd #{path}/#{repo[:name]} && git remote rm origin && git remote add origin #{repo[:path]} && git fetch origin +refs/pull/*:refs/remotes/origin/pr/* +refs/heads/*:refs/remotes/origin/* && git clean -fdx && git checkout -f #{repo[:rev]}", {:accept_all_exit_codes=>true} ).exactly( 1 ).times
      expect( subject ).to receive( :on ).with( host, "cd #{path}/#{repo[:name]} && if [ -f install.rb ]; then ruby ./install.rb ; else true; fi", {:accept_all_exit_codes=>true} ).exactly( 1 ).times

      subject.instance_variable_set( :@metadata, {} )
      subject.install_from_git_on( host, path, repo )
    end
   end

  describe '#install_puppet' do
    let(:hosts) do
      make_hosts({:platform => platform })
    end

    before do
      allow( subject ).to receive(:options).and_return(opts)
      allow( subject ).to receive(:hosts).and_return(hosts)
      allow( subject ).to receive(:on).and_return(Beaker::Result.new({},''))
    end
    context 'on el-6' do
      let(:platform) { Beaker::Platform.new('el-6-i386') }
      it 'installs' do
        expect(hosts[0]).to receive(:install_package_with_rpm).with(/puppet-release-el-6\.noarch\.rpm/, '--replacepkgs', {:package_proxy=>false})
        expect(hosts[0]).to receive(:install_package).with('puppet')
        subject.install_puppet
      end
      it 'installs in parallel' do
        InParallel::InParallelExecutor.logger = logger
        FakeFS.deactivate!
        hosts.each{ |host|
          allow(host).to receive(:install_package_with_rpm).with(/puppet-release-el-6\.noarch\.rpm/, '--replacepkgs', {:package_proxy=>false})
          allow(host).to receive(:install_package).with('puppet')
        }
        opts[:run_in_parallel] = true
        # This will only get hit if forking processes is supported and at least 2 items are being submitted to run in parallel
        expect( InParallel::InParallelExecutor ).to receive(:_execute_in_parallel).with(any_args).and_call_original.exactly(3).times
        subject.install_puppet(opts)
      end
      it 'installs specific version of puppet when passed :version' do
        expect(hosts[0]).to receive(:install_package).with('puppet-3')
        subject.install_puppet( :version => '3' )
      end
      it 'can install specific versions of puppets dependencies' do
        expect(hosts[0]).to receive(:install_package).with('puppet-3')
        expect(hosts[0]).to receive(:install_package).with('hiera-2001')
        expect(hosts[0]).to receive(:install_package).with('facter-1999')
        subject.install_puppet( :version => '3', :facter_version => '1999', :hiera_version => '2001' )
      end
    end
    context 'on el-5' do
      let(:platform) { Beaker::Platform.new('el-5-i386') }
      it 'installs' do
        expect(hosts[0]).to receive(:install_package_with_rpm).with(%r{puppet-release-el-5.noarch.rpm}, '--replacepkgs', {:package_proxy=>false})
        expect(hosts[0]).to receive(:install_package).with('puppet')
        subject.install_puppet
      end
    end
    context 'on fedora' do
      let(:platform) { Beaker::Platform.new('fedora-18-x86_84') }
      it 'installs' do
        expect(hosts[0]).to receive(:install_package_with_rpm).with(%r{puppet-release-fedora-18.noarch.rpm}, '--replacepkgs', {:package_proxy=>false})
        expect(hosts[0]).to receive(:install_package).with('puppet')
        subject.install_puppet
      end
    end
    context 'on archlinux' do
      let(:platform) { Beaker::Platform.new('archlinux-2015.09.01-x86_84') }
      it 'installs' do
        expect(hosts[0]).to receive(:install_package).with('puppet')
        subject.install_puppet
      end
    end
    context 'on freebsd' do
      let(:platform) { Beaker::Platform.new('freebsd-13-amd64') }
      it 'installs' do
        expect(hosts[0]).to receive(:install_package).with('sysutils/puppet7')
        subject.install_puppet
      end
    end
    context 'on debian' do
      PlatformHelpers::DEBIANPLATFORMS.each do |platform|
        let(:platform) { Beaker::Platform.new("#{platform}-ver-arch") }
        it "installs latest on #{platform} if given no version info" do
          hosts.each do |host|
            expect(subject).to receive(:install_puppetlabs_release_repo).with(host)
          end
          expect(hosts[0]).to receive(:install_package).with('puppet')
          subject.install_puppet
        end
      end
      it 'installs specific version of puppet when passed :version' do
        expect(hosts[0]).to receive(:install_package).with('puppet=3-1puppetlabs1')
        expect(hosts[0]).to receive(:install_package).with('puppet-common=3-1puppetlabs1')
        subject.install_puppet( :version => '3' )
      end
      it 'can install specific versions of puppets dependencies' do
        expect(hosts[0]).to receive(:install_package).with('facter=1999-1puppetlabs1')
        expect(hosts[0]).to receive(:install_package).with('hiera=2001-1puppetlabs1')
        expect(hosts[0]).to receive(:install_package).with('puppet-common=3-1puppetlabs1')
        expect(hosts[0]).to receive(:install_package).with('puppet=3-1puppetlabs1')
        subject.install_puppet( :version => '3', :facter_version => '1999', :hiera_version => '2001' )
      end
    end
    context 'on windows' do
      let(:platform) { Beaker::Platform.new('windows-2008r2-i386') }

      before :each do
        allow(winhost).to receive(:tmpdir).and_return(win_temp)
        allow(winhost).to receive(:is_cygwin?).and_return(true)
        allow(subject).to receive(:link_exists?).and_return( true )
        allow(subject).to receive(:install_msi_on).with(any_args)
      end

      it 'installs specific version of puppet when passed :version' do
        hosts.each do |host|
          if host != winhost
            allow(subject).to receive(:on).with(host, anything)
          else
            expect(subject).to receive(:on).with(winhost, "curl -o \"#{win_temp}\\puppet-3.msi\" -O http://downloads.puppet.com/windows/puppet-3.msi")
            expect(subject).to receive(:on).with(winhost, " echo 'export PATH=$PATH:\"/cygdrive/c/Program Files (x86)/Puppet Labs/Puppet/bin\":\"/cygdrive/c/Program Files/Puppet Labs/Puppet/bin\"' > /etc/bash.bashrc ")
            expect(subject).to receive(:install_msi_on).with(winhost, "#{win_temp}\\puppet-3.msi", {}, {:debug => nil}).exactly(1).times
          end
        end
        subject.install_puppet(:version => '3')
      end
      it 'installs from custom url when passed :win_download_url' do
        hosts.each do |host|
          if host != winhost
            allow(subject).to receive(:on).with(host, anything)
          else
            expect(subject).to receive(:on).with(winhost, "curl -o \"#{win_temp}\\puppet-3.msi\" -O http://nightlies.puppet.com/puppet-latest/repos/windows/puppet-3.msi")
            expect(subject).to receive(:install_msi_on).with(winhost, "#{win_temp}\\puppet-3.msi", {}, {:debug => nil})
          end
        end
        subject.install_puppet( :version => '3', :win_download_url => 'http://nightlies.puppet.com/puppet-latest/repos/windows' )
      end
    end
    describe 'on unsupported platforms' do
      let(:platform) { Beaker::Platform.new('solaris-11-x86_64') }
      let(:host) { make_host('henry', :platform => 'solaris-11-x86_64') }
      let(:hosts) { [host] }
      it 'by default raises an error' do
        expect(subject).to_not receive(:on)
        expect { subject.install_puppet }.to raise_error(/unsupported platform/)
      end
      it 'falls back to installing from gem when given :default_action => "gem_install"' do
        result = double
        gem_env_string = '{"RubyGems Environment": [ {"GEM PATHS": [], "EXECUTABLE DIRECTORY": "/does/not/exist" } ] }'
        allow( result ).to receive(:stdout).and_return gem_env_string
        allow(subject).to receive(:on).with(host, /gem environment/).and_return result
        expect(subject).to receive(:on).with(host, /gem install/)
        subject.install_puppet :default_action => 'gem_install'
      end
    end
  end

  describe 'configure_puppet_on' do
    context 'on debian' do
      PlatformHelpers::DEBIANPLATFORMS.each do |platform|
        let(:platform) { Beaker::Platform.new("#{platform}-ver-arch") }
        let(:host) { make_host('testbox.test.local', :platform => "#{platform}") }
        it "it sets the puppet.conf file to the provided config on #{platform}" do
          config = { 'main' => {'server' => 'testbox.test.local'} }
          expected_config_string = "[main]\nserver=testbox.test.local\n\n"

          expect( subject ).to receive( :create_remote_file ).with(
              host, anything, expected_config_string
          )
          subject.configure_puppet_on(host, config)
        end
      end
    end
    context 'on windows' do
      let(:platform) { 'windows-2008R2-amd64' }
      let(:host) { make_host('testbox.test.local', :platform => 'windows-2008R2-amd64') }

      it 'it sets the puppet.conf file to the provided config' do
        config = { 'main' => {'server' => 'testbox.test.local'} }
        expected_config_string = "[main]\nserver=testbox.test.local\n\n"

        expect( subject ).to receive( :create_remote_file ).with(
          host, anything, expected_config_string
        )
        subject.configure_puppet_on(host, config)
      end
    end
  end

  describe 'configure_puppet' do
    let(:hosts) do
      make_hosts({:platform => platform })
    end

    before do
      allow( subject ).to receive(:hosts).and_return(hosts)
      allow( subject ).to receive(:on).and_return(Beaker::Result.new({},''))
    end

    context 'on debian' do
      PlatformHelpers::DEBIANPLATFORMS.each do |platform|
        let(:platform) { Beaker::Platform.new("#{platform}-ver-arch") }
        it "calls configure_puppet_on correctly on #{platform}" do
          config = { 'main' => {'server' => 'testbox.test.local'} }
          expect( subject ).to receive( :configure_puppet_on ).with(
              anything, config
          ).exactly( hosts.length ).times
          subject.configure_puppet(config)
        end
      end
    end

    context 'on windows' do
      let(:platform) { 'windows-2008R2-amd64' }

      it 'calls configure_puppet_on correctly' do
        config = { 'main' => {'server' => 'testbox.test.local'} }
        expect( subject ).to receive( :configure_puppet_on ).with(
          anything, config
        ).exactly( hosts.length ).times
        subject.configure_puppet(config)
      end
    end
  end

  describe "#install_puppetlabs_release_repo" do
    let( :platform ) { Beaker::Platform.new('solaris-7-i386') }
    let( :host ) do
      FakeHost.create('fakevm', platform.to_s)
    end

    before do
      allow(subject).to receive(:options) { opts }
      allow( subject ).to receive( :configure_foss_defaults_on ).and_return( true )
    end

    describe "When host is unsupported platform" do
      let( :platform ) { Beaker::Platform.new('solaris-7-i386') }

      it "raises an exception." do
        expect{
          subject.install_puppetlabs_release_repo host
        }.to raise_error(RuntimeError, /No repository installation step for/)
      end
    end

    describe "When host is a debian-like platform" do
      let( :platform ) { Beaker::Platform.new('debian-7-i386') }

      it "downloads a deb file, installs, and updates the apt cache." do
        expect(subject).to receive(:on).with( host, /wget .*/ ).ordered
        expect(subject).to receive(:on).with( host, /dpkg .*/ ).ordered
        expect(subject).to receive(:on).with( host, "apt-get update" ).ordered
        subject.install_puppetlabs_release_repo host
      end

    end

  end

  describe '#install_puppetlabs_release_repo_on' do
    let( :host ) do
      FakeHost.create( 'fakevm', platform.to_s )
    end

    before :each do
      allow( subject ).to receive( :options ) { opts }
    end

    context 'on el 7' do
      let( :platform ) { Beaker::Platform.new( 'el-7-x86_64' ) }
      it 'returns the correct url when repo is set to puppet8' do
        expect( host ).to receive( :install_package_with_rpm ).with( /puppet8-release-el-7\.noarch\.rpm$/, '--replacepkgs', {:package_proxy=>false} )
        subject.install_puppetlabs_release_repo_on( host, 'puppet8')
      end
      it 'returns the correct url when opts[:puppet_collection] is set to puppet14' do
        expect( host ).to receive( :install_package_with_rpm ).with( /puppet14-release-el-7\.noarch\.rpm$/, '--replacepkgs', {:package_proxy=>false} )
        subject.install_puppetlabs_release_repo_on( host, nil, {:puppet_collection => 'puppet14'})
      end
      it 'returns the correct url when both repo and opts[:puppet_collection] are nil' do
        expect( host ).to receive( :install_package_with_rpm ).with( /puppet-release-el-7\.noarch\.rpm$/, '--replacepkgs', {:package_proxy=>false} )
        subject.install_puppetlabs_release_repo_on( host )
      end
    end

    context 'on debian 8' do
      let( :platform ) { Beaker::Platform.new( 'debian-8-i386' ) }
      it 'returns the correct url when repo is set to puppet4' do
        expect( subject ).to receive( :on ).with( host, /puppet4-release-jessie\.deb$/ ).once
        expect( subject ).to receive( :on ).with( host, "dpkg -i --force-all /tmp/puppet.deb" ).once
        expect( subject ).to receive( :on ).with( host, "apt-get update" ).once
        subject.install_puppetlabs_release_repo_on( host, 'puppet4' )
      end
      it 'returns the correct url when opts[:puppet_collection] is set to puppet7' do
        expect( subject ).to receive( :on ).with( host, /puppet7-release-jessie\.deb$/ ).once
        expect( subject ).to receive( :on ).with( host, "dpkg -i --force-all /tmp/puppet.deb" ).once
        expect( subject ).to receive( :on ).with( host, "apt-get update" ).once
        subject.install_puppetlabs_release_repo_on( host, nil, {:puppet_collection => 'puppet7'} )
      end
      it 'returns the correct url when both repo and opts[:puppet_collection] are nil' do
        expect( subject ).to receive( :on ).with( host, /puppet-release-jessie\.deb$/ ).once
        expect( subject ).to receive( :on ).with( host, "dpkg -i --force-all /tmp/puppet.deb" ).once
        expect( subject ).to receive( :on ).with( host, "apt-get update" ).once
        subject.install_puppetlabs_release_repo_on( host )
      end
    end


    context 'on cisco platforms' do
      context 'version 5' do
        let( :platform ) { Beaker::Platform.new( 'cisco_nexus-7-x86_64' ) }

        it 'calls host.install_package' do
          expect( host ).to receive( :install_package ).with( /\.rpm$/ )
          subject.install_puppetlabs_release_repo_on( host )
        end
      end

      context 'version 7' do
        let( :platform ) { Beaker::Platform.new( 'cisco_ios_xr-6-x86_64' ) }

        it 'uses yum localinstall to install the package' do
          expect( subject ).to receive( :on ).with( host, /^yum.*localinstall.*\.rpm$/ )
          subject.install_puppetlabs_release_repo_on( host )
        end
      end
    end

  end

  describe "#install_puppetlabs_dev_repo" do
    let( :package_name ) { "puppet" }
    let( :package_version ) { "7.5.6" }
    let( :host ) do
      h = FakeHost.create('fakvm', platform.to_s, opts)
      allow( h ).to receive( :link_exists? ).and_return( true )
      h
    end
    let( :logger_double ) do
      logger_double = Object.new
      allow(logger_double).to receive(:debug)
      allow(logger_double).to receive(:trace)
      allow( subject ).to receive( :configure_foss_defaults_on ).and_return( true )
      subject.instance_variable_set(:@logger, logger_double)
      logger_double
    end

    RSpec.shared_examples "install-dev-repo" do

      it "scp's files to SUT then modifies them with find-and-sed 2-hit combo" do
        allow(rez).to receive(:exit_code) { 0 }
        allow(subject).to receive(:link_exists?).and_return(true)
        expect(subject).to receive(:scp_to).with( host, repo_config, /.*/ ).ordered
        subject.install_puppetlabs_dev_repo host, package_name, package_version
      end

    end

    describe "When host is unsupported platform" do
      let( :platform ) { Beaker::Platform.new('solaris-7-i386') }

      it "raises an exception." do
        # expect(subject).to receive(:on).with( host, /^mkdir -p .*$/ ).ordered
        allow(subject).to receive(:options) { opts }
        expect{
          subject.install_puppetlabs_dev_repo host, package_name, package_version
        }.to raise_error(RuntimeError, /No repository installation step for/)
      end
    end

    describe 'When on supported platforms' do
      # These are not factored into the `before` block above because they
      # are expectations in the share examples, but aren't interesting
      # beyond those basic tests
      def stub_uninteresting_portions_of_install_puppetlabs_dev_repo!
        allow(subject).to receive(:scp_to).with( host, repo_config, /.*/ ).ordered
      end

      let( :repo_config ) { "repoconfig" }
      let( :repo_dir ) { "repodir" }
      let( :rez ) { double }

      before do
        allow(subject).to receive(:fetch_http_file) { repo_config }
        allow(subject).to receive(:fetch_http_dir) { repo_dir }
        allow(subject).to receive(:on).with(host, "apt-get update") { }
        allow(subject).to receive(:options) { opts }
        allow(subject).to receive(:on).with( host, /^.* -d .*/, {:acceptable_exit_codes =>[0,1]} ).and_return(rez)
      end

      describe "that are debian-like" do
        PlatformHelpers::DEBIANPLATFORMS.each do |platform|
          let(:platform) { Beaker::Platform.new("#{platform}-ver-arch") }
          before { allow(subject).to receive(:link_exists?).and_return(true) }

          include_examples "install-dev-repo"

        end
      end

      describe "that are redhat-like" do
        let( :platform ) { Beaker::Platform.new('el-7-i386') }
        include_examples "install-dev-repo"
      end
    end
  end

  describe '#install_packages_from_local_dev_repo' do
    let( :package_name ) { 'puppet-agent' }
    let( :platform ) { @platform || 'other' }
    let( :host ) do
      FakeHost.create('fakvm', platform, opts)
    end

    before :each do
      allow( subject ).to receive( :configure_foss_defaults_on ).and_return( true )
    end

    it 'sets the find command correctly for el-based systems' do
      @platform = 'el-1-3'
      expect( subject ).to receive( :on ).with( host, /\*\.rpm.+rpm\s-ivh/ )
      subject.install_packages_from_local_dev_repo( host, package_name )
    end

    it 'sets the find command correctly for debian-based systems' do
      @platform = 'debian-1-3'
      expect( subject ).to receive( :on ).with( host, /\*\.deb.+dpkg\s-i/ )
      subject.install_packages_from_local_dev_repo( host, package_name )
    end

    it 'fails correctly for systems not accounted for' do
      @platform = 'eos-1-3'
      expect{ subject.install_packages_from_local_dev_repo( host, package_name ) }.to raise_error RuntimeError
    end

  end

  describe '#msi_link_path' do
    let( :opts )     { { :puppet_agent_version => 'VERSION', :win_download_url => 'http://downloads.puppet.com/windows' } }
    let( :platform ) { 'windows' }
    let( :host )     { { :platform => platform, 'dist' => 'puppet-agent-VERSION-x64' } }

    it 'returns the right link when puppet collection is set' do
      allow(subject).to receive(:link_exists?).with(anything()).and_return( true )

      expect(subject.msi_link_path( host, opts.merge({:puppet_collection => 'puppet'}) )).to eq "#{opts[:win_download_url]}/puppet/puppet-agent-VERSION-x64.msi"
    end

    it 'returns the right link when puppet collection is not set' do
      expect(subject).to receive(:link_exists?).with(anything()).and_return( true )

      expect(subject.msi_link_path( host, opts )).to eq "#{opts[:win_download_url]}/puppet-agent-VERSION-x64.msi"
    end

    it 'returns error when link incorrect' do
      allow(subject).to receive(:link_exists?).with(anything()).and_return( false )

      expect{
        subject.msi_link_path( host, opts )
      }.to raise_error(RuntimeError, /Puppet MSI at http:\/\/downloads.puppet.com\/windows\/puppet-agent-VERSION-x64.msi does not exist!/)
    end
  end

  describe '#install_puppet_agent_from_msi_on' do
    let( :opts )     { { :puppet_agent_version => 'VERSION', :win_download_url => 'http://downloads.puppet.com/windows' } }
    let( :platform ) { 'windows' }
    let( :host )     { { :platform => platform } }

    it 'uses x86 msi when host is_x86_64 and install_32 is set on the host' do
      host['install_32'] = true

      expect( host ).to receive( :is_x86_64? ).and_return( true )
      expect( subject ).to receive( :install_a_puppet_msi_on ).with( host, opts )

      subject.install_puppet_agent_from_msi_on( host, opts )
      expect( host['dist'] ).to be == "puppet-agent-VERSION-x86"

    end

    it 'uses x86 msi when host is_x86_64 and install_32 is set on the options' do
      opts['install_32'] = true

      expect( host ).to receive( :is_x86_64? ).and_return( true )
      expect( subject ).to receive( :install_a_puppet_msi_on ).with( host, opts )

      subject.install_puppet_agent_from_msi_on( host, opts )
      expect( host['dist'] ).to be == "puppet-agent-VERSION-x86"

    end

    it 'uses x86 msi when host is_x86_64 and ruby_arch is x86 on the host' do
      host['ruby_arch'] = 'x86'

      expect( host ).to receive( :is_x86_64? ).and_return( true )
      expect( subject ).to receive( :install_a_puppet_msi_on ).with( host, opts )

      subject.install_puppet_agent_from_msi_on( host, opts )
      expect( host['dist'] ).to be == "puppet-agent-VERSION-x86"

    end

    it 'uses x86 msi when host !is_x86_64' do

      expect( host ).to receive( :is_x86_64? ).and_return( false )
      expect( subject ).to receive( :install_a_puppet_msi_on ).with( host, opts )

      subject.install_puppet_agent_from_msi_on( host, opts )
      expect( host['dist'] ).to be == "puppet-agent-VERSION-x86"

    end

    it 'uses x64 msi when host is_x86_64, no install_32 and ruby_arch != x86' do

      expect( host ).to receive( :is_x86_64? ).and_return( true )
      expect( subject ).to receive( :install_a_puppet_msi_on ).with( host, opts )

      subject.install_puppet_agent_from_msi_on( host, opts )
      expect( host['dist'] ).to be == "puppet-agent-VERSION-x64"

    end
  end

  describe '#install_cert_on_windows' do
    before do
      allow(subject).to receive(:on).and_return(Beaker::Result.new({},''))
    end

    context 'on windows' do
      let(:platform) { 'windows-2008R2-amd64' }
      let(:host) { make_host('testbox.test.local', :platform => 'windows-2008R2-amd64') }

      it 'should install all 3 certs' do
        cert = 'geotrust_global_ca'
        content = <<-EOM
        -----BEGIN CERTIFICATE-----
        MIIDVDCCAjygAwIBAgIDAjRWMA0GCSqGSIb3DQEBBQUAMEIxCzAJBgNVBAYTAlVT
        MRYwFAYDVQQKEw1HZW9UcnVzdCBJbmMuMRswGQYDVQQDExJHZW9UcnVzdCBHbG9i
        YWwgQ0EwHhcNMDIwNTIxMDQwMDAwWhcNMjIwNTIxMDQwMDAwWjBCMQswCQYDVQQG
        EwJVUzEWMBQGA1UEChMNR2VvVHJ1c3QgSW5jLjEbMBkGA1UEAxMSR2VvVHJ1c3Qg
        R2xvYmFsIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2swYYzD9
        9BcjGlZ+W988bDjkcbd4kdS8odhM+KhDtgPpTSEHCIjaWC9mOSm9BXiLnTjoBbdq
        fnGk5sRgprDvgOSJKA+eJdbtg/OtppHHmMlCGDUUna2YRpIuT8rxh0PBFpVXLVDv
        iS2Aelet8u5fa9IAjbkU+BQVNdnARqN7csiRv8lVK83Qlz6cJmTM386DGXHKTubU
        1XupGc1V3sjs0l44U+VcT4wt/lAjNvxm5suOpDkZALeVAjmRCw7+OC7RHQWa9k0+
        bw8HHa8sHo9gOeL6NlMTOdReJivbPagUvTLrGAMoUgRx5aszPeE4uwc2hGKceeoW
        MPRfwCvocWvk+QIDAQABo1MwUTAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTA
        ephojYn7qwVkDBF9qn1luMrMTjAfBgNVHSMEGDAWgBTAephojYn7qwVkDBF9qn1l
        uMrMTjANBgkqhkiG9w0BAQUFAAOCAQEANeMpauUvXVSOKVCUn5kaFOSPeCpilKIn
        Z57QzxpeR+nBsqTP3UEaBU6bS+5Kb1VSsyShNwrrZHYqLizz/Tt1kL/6cdjHPTfS
        tQWVYrmm3ok9Nns4d0iXrKYgjy6myQzCsplFAMfOEVEiIuCl6rYVSAlk6l5PdPcF
        PseKUgzbFbS9bZvlxrFUaKnjaZC2mqUPuLk/IH2uSrW4nOQdtqvmlKXBx4Ot2/Un
        hw4EbNX/3aBd7YdStysVAq45pmp06drE57xNNB6pXE0zX5IJL4hmXXeXxx12E6nV
        5fEWCRE11azbJHFwLJhWC9kXtNHjUStedejV0NxPNO3CBWaAocvmMw==
        -----END CERTIFICATE-----
        EOM

        expect(subject).to receive(:create_remote_file) do |host, file_path, file_content|
          expect(file_path).to eq("C:\\Windows\\Temp\\#{cert}.pem")
        end

        expect(subject).to receive(:on) do |host, command|
          expect(command).to eq("certutil -v -addstore Root C:\\Windows\\Temp\\#{cert}.pem")
        end

        subject.install_cert_on_windows(host, cert, content)
      end
    end
  end

  describe '#install_puppetserver_on' do
    let(:host) { make_host('master', platform: 'el-7-x86_64') }

    context 'with default arguments' do
      it "installs the latest puppetserver from the default 'puppet' release stream" do
        expect(subject).to receive(:install_puppetlabs_release_repo_on).with(host, 'puppet', include(release_yum_repo_url: "https://yum.puppet.com"))
        expect(subject).to receive(:install_package).with(host, 'puppetserver', nil)
        subject.install_puppetserver_on(host)
      end
    end

    context 'with a version option' do
      version = '6.6.6'

      context 'on deb-based platform' do
        let(:host) {make_host('master', platform: Beaker::Platform.new('ubuntu-16.04-amd64'))}
        it 'munges the version on ubuntu 16.04' do
          expect(subject).to receive(:install_puppetlabs_release_repo_on).with(host, 'puppet', anything)
          expect(subject).to receive(:install_package).with(host, 'puppetserver', "#{version}-1xenial")
          allow(subject).to receive(:dev_builds_accessible_on?).with(host, anything).and_return false
          subject.install_puppetserver_on(host, version: version)
        end
      end

      it 'installs puppetserver at the specific version from internal buildservers' do
        expect(subject).to receive(:install_from_build_data_url).with('puppetserver', /^#{described_class::FOSS_DEFAULT_DOWNLOAD_URLS[:dev_builds_url]}.*#{version}/, host)
        allow(subject).to receive(:dev_builds_accessible_on?).with(host, anything).and_return true
        subject.install_puppetserver_on(host, version: version)
      end

      it 'installs puppetserver from the custom dev builds URL' do
        dev_builds_url = 'http://builds.corp.tld'
        expect(subject).to receive(:install_from_build_data_url).with('puppetserver', /^#{dev_builds_url}.*#{version}/, host)
        allow(subject).to receive(:dev_builds_accessible_on?).with(host, anything).and_return true
        subject.install_puppetserver_on(host, version: version, dev_builds_url: dev_builds_url)
      end

      it 'installs puppetserver from the main repo if a broken url is passed in' do
        dev_builds_url = 'http://builds.corp.tld'
        allow(subject).to receive(:dev_builds_accessible_on?).with(host, dev_builds_url).and_return false
        expect(subject).to receive(:install_puppetlabs_release_repo_on).with(host, 'puppet', include(version: '6.6.6'))
        expect(subject).to receive(:install_package).with(host, 'puppetserver', '6.6.6')
        subject.install_puppetserver_on(host, version: version, dev_builds_url: dev_builds_url)
      end

      it 'installs from a custom release stream' do
        release_stream = 'puppet6'
        allow(subject).to receive(:dev_builds_accessible_on?).with(host, anything).and_return false
        expect(subject).to receive(:install_puppetlabs_release_repo_on).with(host,
                                                                             release_stream,
                                                                             include(version: '6.6.6'))
        expect(subject).to receive(:install_package).with(host, 'puppetserver', '6.6.6')
        subject.install_puppetserver_on(host, release_stream: release_stream, version: version)
      end

      it 'installs puppetserver from the default release stream' do
        allow(subject).to receive(:dev_builds_accessible_on?).with(host, anything).and_return false
        expect(subject).to receive(:install_puppetlabs_release_repo_on).with(host, 'puppet', include(version: '6.6.6'))
        expect(subject).to receive(:install_package).with(host, 'puppetserver', '6.6.6')
        subject.install_puppetserver_on(host, version: version)
      end
    end

    context 'with the nightlies option' do
      it 'installs puppetserver from the default puppet nightly repos' do
        expect(subject).to receive(:install_puppetlabs_release_repo_on)
                               .with(host, 'puppet-nightly', include(
                                     nightly_yum_repo_url: described_class::FOSS_DEFAULT_DOWNLOAD_URLS[:nightly_yum_repo_url],
                                     nightly_apt_repo_url: described_class::FOSS_DEFAULT_DOWNLOAD_URLS[:nightly_apt_repo_url]))
        subject.install_puppetserver_on(host, nightlies: true)
      end

      context 'with custom nightlies urls' do
        custom_nightlies_url = 'http://nightlies.corp.tld'

        it 'uses a custom general nightlies url' do
          expect(subject).to receive(:install_puppetlabs_release_repo_on)
                                 .with(host, 'puppet-nightly', include(
                                       nightly_yum_repo_url: custom_nightlies_url,
                                       nightly_apt_repo_url: custom_nightlies_url))
          subject.install_puppetserver_on(host, nightlies: true, nightly_builds_url: custom_nightlies_url)
        end

        it 'uses a custom yum repo url' do
          expect(subject).to receive(:install_puppetlabs_release_repo_on)
                                 .with(host, 'puppet-nightly', include(
                                       nightly_yum_repo_url: custom_nightlies_url))
          subject.install_puppetserver_on(host, nightlies: true, nightly_yum_repo_url: custom_nightlies_url)
        end

        it 'uses a custom apt repo url' do
          expect(subject).to receive(:install_puppetlabs_release_repo_on)
                                 .with(host, 'puppet-nightly', include(
                                       nightly_apt_repo_url: custom_nightlies_url))
          subject.install_puppetserver_on(host, nightlies: true, nightly_apt_repo_url: custom_nightlies_url)
        end
      end
    end
  end

  describe '#remove_puppet_on' do
    supported_platforms   = [ 'aix-53-power',
                              'aix-61-power',
                              'aix-71-power',
                              'solaris-10-x86_64',
                              'solaris-10-x86_64',
                              'solaris-11-x86_64',
                              'el-6-x86_64',
                              'redhat-7-x86_64',
                              'centos-7-x86_64',
                              'oracle-7-x86_64',
                              'scientific-7-x86_64',
                              'sles-10-x86_64',
                              'sles-11-x86_64',
                              'sles-12-s390x',
                              'ubuntu-16.04-power8'
                            ]

    supported_platforms.each do |platform|
      let(:host) { make_host(platform, :platform => platform) }

      pkg_list = 'foo bar'

      it "uninstalls packages on #{platform}" do
        result = Beaker::Result.new(host,'')
        result.stdout = pkg_list

        expected_list = pkg_list
        cmd_args = ''

        expect( subject ).to receive(:on).exactly(2).times.and_return(result, result)
        expect( host ).to receive(:uninstall_package).with(expected_list, cmd_args)

        subject.remove_puppet_on( host )
      end
    end

    let(:debian6) { make_host('debian-6-amd64', :platform => 'debian-6-amd64') }
    it 'raises error on unsupported platforms' do
      expect { subject.remove_puppet_on( debian6 ) }.to raise_error(RuntimeError, /unsupported platform/)
    end

  end
end
