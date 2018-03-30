extend BeakerPuppet::Install::Puppet5
extend Beaker::DSL::InstallUtils::FOSSUtils

test_name "Install Puppet Server" do
  skip_test "not testing with puppetserver" unless @options['is_puppetserver']

  server_version = ENV['SERVER_VERSION'] || 'latest'
  release_stream = ENV['RELEASE_STREAM'] || 'puppet'
  nightly_builds_url = ENV['NIGHTLY_BUILDS_URL'] || 'http://nightlies.puppet.com'
  dev_builds_url  = ENV['DEV_BUILDS_URL'] || 'http://builds.delivery.puppetlabs.net'

  if nightly_builds_url == 'http://nightlies.puppet.com'
    yum_nightlies_url = nightly_builds_url + '/yum'
    apt_nightlies_url = nightly_builds_url + '/apt'
  else
    yum_nightlies_url = nightly_builds_url
    apt_nightlies_url = nightly_builds_url
  end

  if server_version == 'latest'
    opts = {
      :release_yum_repo_url => yum_nightlies_url,
      :release_apt_repo_url => apt_nightlies_url
    }
    install_puppetlabs_release_repo_on(master, "#{release_stream}-nightly", opts)
    master.install_package('puppetserver')
  else
    install_from_build_data_url('puppetserver', "#{dev_builds_url}/puppetserver/#{server_version}/artifacts/#{server_version}.yaml", master)
  end
end
