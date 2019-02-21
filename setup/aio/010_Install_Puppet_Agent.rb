test_name "Install Packages" do

  dev_builds_url  = ENV['DEV_BUILDS_URL'] || 'http://builds.delivery.puppetlabs.net'
  nightly_builds_url = ENV['NIGHTLY_BUILDS_URL'] || 'http://nightlies.puppet.com'

  sha = ENV['SHA']
  release_stream = ENV['RELEASE_STREAM'] || 'puppet'

  step "Install puppet-agent..." do
    # If SHA='latest', then we're installing from nightlies
    if sha == 'latest'
      opts = {
        :release_yum_repo_url => nightly_builds_url + '/yum',
        :release_apt_repo_url => nightly_builds_url + '/apt',
        :puppet_collection => "#{release_stream}-nightly"
      }
      install_puppet_agent_on(hosts, opts)
    else
      install_from_build_data_url('puppet-agent', "#{dev_builds_url}/puppet-agent/#{sha}/artifacts/#{sha}.yaml", hosts)
    end
  end

  # make sure install is sane, beaker has already added puppet and ruby
  # to PATH in ~/.ssh/environment
  agents.each do |agent|
    on agent, puppet('--version')
    ruby = ruby_command(agent)
    on agent, "#{ruby} --version"
  end
end
