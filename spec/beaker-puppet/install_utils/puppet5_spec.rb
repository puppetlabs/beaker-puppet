require 'spec_helper'

class ClassMixedWithDSLInstallUtils
  include Beaker::DSL::Outcomes
  include Beaker::DSL::InstallUtils::Puppet5

  def logger
    @logger ||= RSpec::Mocks::Double.new('logger').as_null_object
  end
end

describe ClassMixedWithDSLInstallUtils do
  let(:hosts)   { make_hosts( { :pe_ver => '3.0',
                                      :platform => 'linux',
                                      :roles => [ 'agent' ],
                                      :type  => 'foss' }, 4 ) }

  before :each do
    allow( subject ).to receive( :hosts ) { hosts }
  end


  describe '#fetch_build_details' do
    let( :platform_data ) { @platform_data || '' }
    let( :deets ) { { :platform_data => platform_data } }

    it 'sets & returns the relative folder' do
      sha_yaml_folder = '/jams/of/the/rain'
      sha_yaml_url    = "#{sha_yaml_folder}/puns.tgz"
      expect( subject ).to receive( :fetch_http_file  )
      expect( YAML    ).to receive( :load_file        ) { deets }

      url, _ = subject.fetch_build_details( sha_yaml_url )
      expect( url ).to be === sha_yaml_folder
    end

    it 'fetches & returns the build details' do
      @platform_data = 'test of the man in the can carol?'
      expect( subject ).to receive( :fetch_http_file  )
      expect( YAML    ).to receive( :load_file        ) { deets }

      _, hash = subject.fetch_build_details( 'sha_yaml_url' )
      expect( hash ).to be === @platform_data
    end

    it 'stores the file in a good location' do
      allow( YAML ).to receive( :load_file ) { deets }

      correct_location = '/my/fake/test/dir'
      expect( Dir ).to receive( :mktmpdir ) { correct_location }
      expect( subject ).to receive( :fetch_http_file ).with(
        anything, anything, correct_location
      )
      subject.fetch_build_details( 'sha_yaml_url' )
    end

  end

  describe '#host_urls' do

    let( :artifact_path       ) { @artifact_path      || ''             }
    let( :repo_config         ) { @repo_config        || nil            }
    let( :packaging_platform  ) { @packaging_platform || 'el-7-x86_64'  }
    let( :host                ) {
      host = hosts[0]
      allow( host ).to receive( :[] ).with( :packaging_platform ) {
        packaging_platform
      }
      host
    }
    let( :build_details   ) {
      details = {
        packaging_platform => {
          :artifact     => artifact_path,
          :repo_config  => repo_config
        }
      }
      details
    }

    before :each do
      allow( subject ).to receive( :host_packaging_platform ) { packaging_platform }
    end

    it 'fails if there\'s no artifact value for the given platform' do
      allow( artifact_path ).to receive( :nil? ) { true }
      expect {
        subject.host_urls( host, build_details, '' )
      }.to raise_error(
        Beaker::DSL::Outcomes::FailTest,
        /^no artifact.*path found$/
      )
    end

    it 'fails if the artifact_url doesn\'t exist' do
      allow( subject ).to receive( :link_exists? ) { false }
      expect {
        subject.host_urls( host, build_details, '' )
      }.to raise_error(
        Beaker::DSL::Outcomes::FailTest,
        /^artifact url.*incorrectly$/
      )
    end

    it 'fails if the host doesn\'t have a packaging_platform' do
      allow( packaging_platform ).to receive( :nil? ) { true }
      allow( host ).to receive( :[] ).with( :platform ) { 'fake-platform' }
      expect {
        subject.host_urls( host, build_details, '' )
      }.to raise_error(
        Beaker::DSL::Outcomes::FailTest,
        /packaging_platform not provided for host/
      )
    end

    it 'returns a join of the base_url & the platform-specific artifact path' do
      base_url = 'base_url/base_url'
      @artifact_path = 'pants.install.pkg'

      allow( subject ).to receive( :link_exists? ) { true }
      artifact_url, _ = subject.host_urls( host, build_details, base_url )
      expect( artifact_url ).to be === "#{base_url}/#{@artifact_path}"
    end

    it 'returns a join of the base_url & the platform-specific artifact path' do
      base_url = 'base_url/base_url'
      @repo_config = 'pants.install.list'

      allow( subject ).to receive( :link_exists? ) { true }
      _, repoconfig_url = subject.host_urls( host, build_details, base_url )
      expect( repoconfig_url ).to be === "#{base_url}/#{@repo_config}"
    end

    it 'returns nil for the repoconfig_url if one isn\'t provided by the build_details' do
      allow( subject ).to receive( :link_exists? ) { true }
      _, repoconfig_url = subject.host_urls( host, build_details, '' )
      expect( repoconfig_url ).to be_nil
    end

  end

  describe "#host_packaging_platform" do
    let( :default_platform ) { 'default-platform' }
    let( :overridden_platform ) { 'overridden-platform' }
    let( :overrides ) { 'default-platform=overridden-platform' || @overrides }
    let( :host ) {
      host = hosts[0]
      allow( host ).to receive( :[] ).with( :packaging_platform ) { default_platform }
      allow( host ).to receive( :[] ).with( :platform ) { default_platform }
      host
    }

    before :each do
      @original_platforms = ENV['BEAKER_PACKAGING_PLATFORMS']
    end

    after :each do
      ENV['BEAKER_PACKAGING_PLATFORMS'] = @original_platforms
    end

    it "applies an override to a platform" do
      ENV['BEAKER_PACKAGING_PLATFORMS'] = overrides
      expect(subject.host_packaging_platform(host)).to eq(overridden_platform)
    end

    it "applies a list of overrides to a platform" do
      ENV['BEAKER_PACKAGING_PLATFORMS'] = "aix-7.1-power=aix-6.1-power,#{overrides}"
      expect(subject.host_packaging_platform(host)).to eq(overridden_platform)
    end

    it "doesn't apply overrides if the current host's platform isn't overridden" do
      ENV['BEAKER_PACKAGING_PLATFORMS'] = "aix-7.1-power=aix-6.1-power"
      expect(subject.host_packaging_platform(host)).to eq(default_platform)
    end
  end

  describe '#install_artifact_on' do

    let( :artifact_url ) { 'url://in/the/jungle/lies/the/prize.pnc' }
    let( :platform ) { @platform || 'linux' }
    let( :version ) { @version || '' }
    let( :mock_platform ) {
      mock_platform = Object.new
      allow( mock_platform ).to receive( :to_array ) { [platform, version, '', ''] }
      mock_platform
    }
    let( :host ) {
      host = hosts[0]
      allow( host ).to receive( :[] ).with( :platform ) { mock_platform }
      host
    }

    it 'calls host.install_package in the common case' do
      expect( subject ).to receive( :fetch_http_file ).never
      expect( subject ).to receive( :on ).never
      expect( host ).to receive( :install_local_package ).never
      expect( host ).to receive( :install_package ).once

      subject.install_artifact_on( host, artifact_url, 'project_name' )
    end

    it 'installs from a file on EOS' do
      @platform = 'eos'

      expect(host).to receive(:get_remote_file).with(artifact_url)
      expect(host).to receive(:install_from_file).with(File.basename(artifact_url))

      subject.install_artifact_on(host, artifact_url, 'project_name')
    end

    it 'install a puppet-agent MSI from a URL on Windows' do
      @platform = 'windows'

      expect(subject).to receive(:install_msi_on).with(host, artifact_url)

      subject.install_artifact_on(host, artifact_url, 'puppet-agent')
    end

    it 'install an MSI from a URL on Windows' do
      @platform = 'windows'

      expect(subject).to receive(:generic_install_msi_on).with(host, artifact_url)

      subject.install_artifact_on(host, artifact_url, 'project_name')
    end

    context 'local install cases' do

      def run_shared_test_steps
        expect( host ).to receive( :install_local_package ).once
        expect( host ).to receive( :install_package ).never
        subject.install_artifact_on( host, artifact_url, 'project_name' )
      end

      it 'SOLARIS: fetches the file & runs local install' do
        @platform = 'solaris'

        expect( subject ).to receive( :fetch_http_file ).once
        expect( subject ).to receive( :scp_to ).once
        run_shared_test_steps()
      end

      it 'OSX: curls the file & runs local install' do
        @platform = 'osx'

        expect( subject ).to receive( :on ).with( host, /^curl.*#{artifact_url}$/ )
        run_shared_test_steps()
      end

      it 'AIX: fetches the file & runs local install' do
        @platform = 'aix'
        @version = '7.2'

        expect( subject ).to receive( :fetch_http_file ).once
        expect( subject ).to receive( :scp_to ).once
        expect( subject ).to receive( :on ).with( host, /^rpm -ivh --ignoreos .*#{File.basename(artifact_url)}$/ ).once

        expect( host ).to receive( :install_local_package ).never
        expect( host ).to receive( :install_package ).never
        subject.install_artifact_on( host, artifact_url, 'project_name' )
      end

      it 'AIX 6.1: fetches the file & runs local install' do
        @platform = 'aix'
        @version = '6.1'

        expect( subject ).to receive( :fetch_http_file ).once
        expect( subject ).to receive( :scp_to ).once
        expect( subject ).to receive( :on ).with( host, /^rpm -ivh .*#{File.basename(artifact_url)}$/ ).once
        expect( subject ).not_to receive( :on ).with( host, /^rpm -ivh --ignoreos .*#{File.basename(artifact_url)}$/ )

        expect( host ).to receive( :install_local_package ).never
        expect( host ).to receive( :install_package ).never
        subject.install_artifact_on( host, artifact_url, 'project_name' )
      end

    end

  end

  describe '#install_repo_configs_on' do
    let( :host ) { hosts[0] }

    it 'passes the parameters through to #install_repo_configs_from_url' do
      repoconfig_url = 'string/test/repo_config/stuff.stuff'
      expect( subject ).to receive( :install_repo_configs_from_url ).with(
        host,
        repoconfig_url
      )
      expect( subject.logger ).to receive( :warn ).never
      subject.install_repo_configs_on( host, repoconfig_url )
    end

    it 'returns without calling #install_repo_configs_from_url if repoconfig_url is nil' do
      expect( subject ).to receive( :install_repo_configs_from_url ).never
      expect( subject.logger ).to receive( :warn ).with(
        /^No repo_config.*Skipping repo_config install$/
      )
      subject.install_repo_configs_on( host, nil )
    end
  end

  describe '#install_from_build_data_url' do

    before :each do
      allow( subject ).to receive( :link_exists? ) { true }
    end

    it 'only calls #fetch_build_details once' do
      allow( subject ).to receive( :host_urls )
      allow( subject ).to receive( :install_artifact_on )
      allow( subject ).to receive( :configure_type_defaults_on )

      expect( subject ).to receive( :fetch_build_details ).once
      subject.install_from_build_data_url( 'project_name', 'project_sha' )
    end

    it 'calls #configure_type_defaults_on all hosts' do
      allow( subject ).to receive( :fetch_build_details )
      allow( subject ).to receive( :host_urls )
      allow( subject ).to receive( :install_artifact_on )

      hosts.each do |host|
        expect( subject ).to receive( :configure_type_defaults_on ).with( host ).once
      end
      subject.install_from_build_data_url( 'project_name', 'project_sha' )
    end

    it 'calls #configure_type_defaults_on one host if set' do
      allow( subject ).to receive( :fetch_build_details )
      allow( subject ).to receive( :host_urls )
      allow( subject ).to receive( :install_artifact_on )

      expect( subject ).to receive( :configure_type_defaults_on ).with( hosts[0] ).once
      subject.install_from_build_data_url( 'project_name', 'project_sha', hosts[0] )
    end

    it 'calls #configure_type_defaults_on custom array of hosts if set' do
      allow( subject ).to receive( :fetch_build_details )
      allow( subject ).to receive( :host_urls )
      allow( subject ).to receive( :install_artifact_on )

      custom_host_list = hosts.sample(1 + rand(hosts.count))

      custom_host_list.each do |host|
        expect( subject ).to receive( :configure_type_defaults_on ).with( host ).once
      end
      subject.install_from_build_data_url( 'project_name', 'project_sha', custom_host_list )
    end

    it 'passes the artifact_url from #hosts_artifact_url to #install_artifact_on' do
      allow( subject ).to receive( :fetch_build_details )
      allow( subject ).to receive( :configure_type_defaults_on )

      artifact_url = 'url://in/my/shoe/lies/the/trophy.jnk'
      allow( subject ).to receive( :host_urls ) { artifact_url }


      expect( subject ).to receive( :install_artifact_on ).with(
        anything, artifact_url, anything
      ).exactly( hosts.length ).times
      subject.install_from_build_data_url('project_name', 'project_sha' )
    end

    it 'fails properly if the given sha_yaml_url doesn\'t exist' do
      allow( subject ).to receive( :link_exists? ) { false }
      sha_yaml_url = 'pants/to/the/man/jeans.txt'

      expect {
        subject.install_from_build_data_url( 'project_name', sha_yaml_url )
      }.to raise_error(Beaker::DSL::Outcomes::FailTest, /project_name.*#{sha_yaml_url}/)
    end

    it 'runs host.install_package instead of #install_artifact_on if theres a repo_config' do
      repoconfig_url = 'pants/man/shoot/to/the/stars'
      project_name = 'fake_project_66'
      allow( subject ).to receive( :fetch_build_details )
      allow( subject ).to receive( :configure_type_defaults_on )
      allow( subject ).to receive( :host_urls ) { ['', repoconfig_url] }

      expect( subject ).to receive( :install_artifact_on ).never
      hosts.each do |host|
        expect( subject ).to receive( :install_repo_configs_on ).with(
          host,
          repoconfig_url
        )
        expect( host ).to receive( :install_package ).with( project_name )
      end
      subject.install_from_build_data_url( project_name, 'sha_yaml_url' )
    end
  end

  describe '#install_puppet_agent_from_dev_builds_on' do
    let(:host) { make_host('test_host', { platform: 'el-7-x86_64' }) }
    let(:ref) { "sha" }
    let(:sha_yaml_url) { "#{Beaker::DSL::Puppet5::DEFAULT_DEV_BUILDS_URL}/puppet-agent/#{ref}/artifacts/#{ref}.yaml" }

    it 'installs puppet-agent from internal builds when they are accessible' do
      expect( subject ).to receive(:block_on).with(anything, :run_in_parallel => true)
      allow(subject).to receive(:dev_builds_accessible_on?).and_return(true)
      allow(subject).to receive(:install_from_build_data_url).with('puppet-agent', sha_yaml_url, host)
      subject.install_puppet_agent_from_dev_builds_on(host, ref)
      expect(subject).to have_received(:install_from_build_data_url).with('puppet-agent', sha_yaml_url, host)
    end

    it 'fails the test when internal builds are inaccessible' do
      expect( subject ).to receive(:block_on).with(anything, :run_in_parallel => true)
      allow(subject).to receive(:dev_builds_accessible?).and_return(false)
      expect { subject.install_puppet_agent_from_dev_builds_on(host, 'sha') }.to raise_error(Beaker::DSL::Outcomes::FailTest)
    end
  end
end
