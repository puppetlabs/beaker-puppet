require 'spec_helper'

class ClassMixedWithDSLInstallUtils
  include Beaker::DSL::Wrappers
  include Beaker::DSL::Helpers
  include Beaker::DSL::Structure
  include Beaker::DSL::Roles
  include Beaker::DSL::Patterns
  include Beaker::DSL::InstallUtils

  def logger
    @logger ||= RSpec::Mocks::Double.new('logger').as_null_object
  end
end

describe ClassMixedWithDSLInstallUtils do
  let(:metadata)      { @metadata ||= {} }
  let(:presets)       { Beaker::Options::Presets.new }
  let(:opts)          { presets.presets.merge(presets.env_vars) }
  let(:basic_hosts)   { make_hosts( { :pe_ver => '3.0',
                                       :platform => 'linux',
                                       :roles => [ 'agent' ] }, 4 ) }
  let(:hosts)         { basic_hosts[0][:roles] = ['master', 'database', 'dashboard']
                        basic_hosts[1][:platform] = 'windows'
                        basic_hosts[2][:platform] = 'osx-10.9-x86_64'
                        basic_hosts[3][:platform] = 'eos'
                        basic_hosts  }
  let(:hosts_sorted)  { [ hosts[1], hosts[0], hosts[2], hosts[3] ] }
  let(:winhost)       { make_host( 'winhost', { :platform => 'windows',
                                                :pe_ver => '3.0',
                                                :working_dir => '/tmp',
                                                :is_cygwin => true} ) }
  let(:winhost_non_cygwin) { make_host( 'winhost_non_cygwin', { :platform => 'windows',
                                                :pe_ver => '3.0',
                                                :working_dir => '/tmp',
                                                :is_cygwin => 'false' } ) }
  let(:machost)       { make_host( 'machost', { :platform => 'osx-10.9-x86_64',
                                                :pe_ver => '3.0',
                                                :working_dir => '/tmp' } ) }
  let(:unixhost)      { make_host( 'unixhost', { :platform => 'linux',
                                                 :pe_ver => '3.0',
                                                 :working_dir => '/tmp',
                                                 :dist => 'puppet-enterprise-3.1.0-rc0-230-g36c9e5c-debian-7-i386' } ) }
  let(:eoshost)       { make_host( 'eoshost', { :platform => 'eos',
                                                :pe_ver => '3.0',
                                                :working_dir => '/tmp',
                                                :dist => 'puppet-enterprise-3.7.1-rc0-78-gffc958f-eos-4-i386' } ) }

  describe "#configure_defaults_on" do

    it "can set foss defaults" do
      expect(subject).to receive(:add_foss_defaults_on).exactly(hosts.length).times
      subject.configure_defaults_on(hosts, 'foss')
    end

    it "can set aio defaults" do
      expect(subject).to receive(:add_aio_defaults_on).exactly(hosts.length).times
      subject.configure_defaults_on(hosts, 'aio')
    end

    it "can set pe defaults" do
      expect(subject).to receive(:add_pe_defaults_on).exactly(hosts.length).times
      subject.configure_defaults_on(hosts, 'pe')
    end

    it 'can remove old defaults ands replace with new' do
      # fake the results of calling configure_pe_defaults_on
      hosts.each do |host|
        host['type'] = 'pe'
      end
      expect(subject).to receive(:remove_pe_defaults_on).exactly(hosts.length).times
      expect(subject).to receive(:add_foss_defaults_on).exactly(hosts.length).times
      subject.configure_defaults_on(hosts, 'foss')
    end
  end

  describe "#configure_type_defaults_on" do

    it "can set foss defaults for foss type" do
      hosts.each do |host|
        host['type'] = 'foss'
      end
      expect(subject).to receive(:add_foss_defaults_on).exactly(hosts.length).times
      subject.configure_type_defaults_on(hosts)
    end

    it "adds aio defaults to foss hosts when they have an aio foss puppet version" do
      hosts.each do |host|
        host[:pe_ver] = nil
        host[:version] = nil
        host['type'] = 'foss'
        host['version'] = '4.0'
      end
      expect(subject).to receive(:add_foss_defaults_on).exactly(hosts.length).times
      expect(subject).to receive(:add_aio_defaults_on).exactly(hosts.length).times
      subject.configure_type_defaults_on(hosts)
    end

    it "adds aio defaults to foss hosts when they have type foss-aio" do
      hosts.each do |host|
        host[:pe_ver] = nil
        host[:version] = nil
        host['type'] = 'foss-aio'
      end
      expect(subject).to receive(:add_foss_defaults_on).exactly(hosts.length).times
      expect(subject).to receive(:add_aio_defaults_on).exactly(hosts.length).times
      subject.configure_type_defaults_on(hosts)
    end

    it "can set aio defaults for aio type (backwards compatability)" do
      hosts.each do |host|
        host[:pe_ver] = nil
        host[:version] = nil
        host['type'] = 'aio'
      end
      expect(subject).to receive(:add_aio_defaults_on).exactly(hosts.length).times
      subject.configure_type_defaults_on(hosts)
    end

    it "can set pe defaults for pe type" do
      hosts.each do |host|
        host['type'] = 'pe'
      end
      expect(subject).to receive(:add_pe_defaults_on).exactly(hosts.length).times
      subject.configure_type_defaults_on(hosts)
    end

    it "adds aio defaults to pe hosts when they an aio pe version" do
      hosts.each do |host|
        host['type'] = 'pe'
        host['pe_ver'] = '4.0'
      end
      expect(subject).to receive(:add_pe_defaults_on).exactly(hosts.length).times
      expect(subject).to receive(:add_aio_defaults_on).exactly(hosts.length).times
      subject.configure_type_defaults_on(hosts)
    end

  end

  describe '#puppetserver_version_on' do
    it 'returns the tag on a released version' do
      result = object_double(Beaker::Result.new({}, 'puppetserver --version'), :stdout => "puppetserver version: 6.13.0", :exit_code => 0)
      expect(subject).to receive(:on).with(hosts.first, 'puppetserver --version', accept_all_exit_codes: true).and_return(result)
      expect(subject.puppetserver_version_on(hosts.first)).to eq('6.13.0')
    end

    it 'returns the tag on a nightly version' do
      result = object_double(Beaker::Result.new({}, 'puppetserver --version'), :stdout => "puppetserver version: 7.0.0.SNAPSHOT.2020.10.14T0512", :exit_code => 0)
      expect(subject).to receive(:on).with(hosts.first, 'puppetserver --version', accept_all_exit_codes: true).and_return(result)
      expect(subject.puppetserver_version_on(hosts.first)).to eq('7.0.0')
    end
  end

  describe '#puppet_collection_for' do
    it 'raises an error when given an invalid package' do
      expect {
        subject.puppet_collection_for(:foo, '5.5.4')
      }.to raise_error(RuntimeError, /package must be one of puppet_agent, puppet, puppetserver/)
    end

    context 'when the :puppet_agent package is passed in' do
      context 'given a valid version' do
        {
          '1.10.14'     => 'pc1',
          '1.10.x'      => 'pc1',
          '5.3.1'       => 'puppet5',
          '5.3.x'       => 'puppet5',
          '5.99.0'      => 'puppet6',
          '6.1.99-foo'  => 'puppet6',
          '6.99.99'     => 'puppet7',
          '7.0.0'       => 'puppet7',
        }.each do |version, collection|
          it "returns collection '#{collection}' for version '#{version}'" do
            expect(subject.puppet_collection_for(:puppet_agent, version)).to eq(collection)
          end
        end
      end
  
      it "returns the default, latest puppet collection given the version 'latest'" do
        expect(subject.puppet_collection_for(:puppet_agent, 'latest')).to eq('puppet')
      end
  
      context 'given an invalid version' do
        [nil, '', '0.1.0', '3.8.1', '', 'not-semver', 'not.semver.either'].each do |version|
          it "returns a nil collection value for version '#{version}'" do
            expect(subject.puppet_collection_for(:puppet_agent, version)).to be_nil
          end
        end
      end
    end

    context 'when the :puppet package is passed-in' do
      context 'given a valid version' do
        {
          '4.9.0'       => 'pc1',
          '4.10.x'      => 'pc1',
          '5.3.1'       => 'puppet5',
          '5.3.x'       => 'puppet5',
          '5.99.0'      => 'puppet6',
          '6.1.99-foo'  => 'puppet6',
          '6.99.99'     => 'puppet7',
          '7.0.0'       => 'puppet7',
        }.each do |version, collection|
          it "returns collection '#{collection}' for version '#{version}'" do
            expect(subject.puppet_collection_for(:puppet, version)).to eq(collection)
          end
        end
      end

      it "returns the default, latest puppet collection given the version 'latest'" do
        expect(subject.puppet_collection_for(:puppet, 'latest')).to eq('puppet')
      end

      context 'given an invalid version' do
        [nil, '', '0.1.0', '3.8.1', '', 'not-semver', 'not.semver.either'].each do |version|
          it "returns a nil collection value for version '#{version}'" do
            expect(subject.puppet_collection_for(:puppet, version)).to be_nil
          end
        end
      end
    end

    context 'when the :puppetserver package is passed in' do
      context 'given a valid version' do
        {
          '2.0.0'       => 'pc1',
          '2.0.x'       => 'pc1',
          '5.3.1'       => 'puppet5',
          '5.3.x'       => 'puppet5',
          '5.99.0'      => 'puppet6',
          '6.1.99-foo'  => 'puppet6',
          '6.99.99'     => 'puppet7',
          '7.0.0'       => 'puppet7',
        }.each do |version, collection|
          it "returns collection '#{collection}' for version '#{version}'" do
            expect(subject.puppet_collection_for(:puppetserver, version)).to eq(collection)
          end
        end
      end
  
      it "returns the default, latest puppet collection given the version 'latest'" do
        expect(subject.puppet_collection_for(:puppetserver, 'latest')).to eq('puppet')
      end
  
      context 'given an invalid version' do
        [nil, '', '0.1.0', '3.8.1', '', 'not-semver', 'not.semver.either'].each do |version|
          it "returns a nil collection value for version '#{version}'" do
            expect(subject.puppet_collection_for(:puppetserver, version)).to be_nil
          end
        end
      end
    end
  end
end
