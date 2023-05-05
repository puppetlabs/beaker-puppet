test_name 'Install Puppet Agent Packages' do
  opts = {
    nightly_builds_url: ENV.fetch('NIGHTLY_BUILDS_URL', nil),
    dev_builds_url: ENV.fetch('DEV_BUILDS_URL', nil),
    puppet_agent_version: ENV.fetch('SHA', nil),
    puppet_collection: ENV.fetch('RELEASE_STREAM', nil),
  }

  install_puppet_agent_on(hosts, opts)

  # make sure install is sane, beaker has already added puppet and ruby
  # to PATH in ~/.ssh/environment
  agents.each do |agent|
    on agent, puppet('--version')
    ruby = ruby_command(agent)
    on agent, "#{ruby} --version"
  end
end
