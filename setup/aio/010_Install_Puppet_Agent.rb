test_name "Install Packages" do
  step "Install puppet-agent..." do
    install_puppet_agent_from_dev_builds_on(hosts, ENV['SHA'])
  end

  # make sure install is sane, beaker has already added puppet and ruby
  # to PATH in ~/.ssh/environment
  agents.each do |agent|
    on agent, puppet('--version')
    ruby = ruby_command(agent)
    on agent, "#{ruby} --version"
  end
end
