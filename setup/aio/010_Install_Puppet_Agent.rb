test_name "Install Puppet Agent Packages" do

  opts = {
    :nightly_builds_url => ENV['NIGHTLY_BUILDS_URL'],
    :dev_builds_url => ENV['DEV_BUILDS_URL'],
    :puppet_agent_version => ENV['SHA'],
    :puppet_collection => ENV['RELEASE_STREAM']
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
