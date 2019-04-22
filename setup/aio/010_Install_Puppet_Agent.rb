test_name "Install Packages" do

  opts = {
    :puppet_agent_version => ENV['SHA'],
    :puppet_collection => ENV['RELEASE_STREAM'],
    :dev_builds_url => ENV['DEV_BUILDS_URL'],
    :nightly_builds_url => ENV['NIGHTLY_BUILDS_URL']
  }
  install_puppet_agent_on(agents, opts)


  # make sure install is sane, beaker has already added puppet and ruby
  # to PATH in ~/.ssh/environment
  agents.each do |agent|
    on agent, puppet('--version')
    ruby = ruby_command(agent)
    on agent, "#{ruby} --version"
  end
end
