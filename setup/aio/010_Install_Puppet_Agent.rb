test_name 'Install Puppet Agent Packages' do
  agents.each do |agent|
    path = ENV.fetch('DEV_BUILD_PATH', nil)
    if path
      raise ArgumentError, "The path #{path} does not exist" unless File.exist?(path)

      basename = File.basename(path)
      scp_to(agent, path, basename)

      # configure locations for ruby, puppet, config files, etc
      add_aio_defaults_on(agent)
      agent.install_package(basename)
    else
      opts = {
        nightly_builds_url: ENV.fetch('NIGHTLY_BUILDS_URL', nil),
        dev_builds_url: ENV.fetch('DEV_BUILDS_URL', nil),
        puppet_agent_version: ENV.fetch('SHA', nil),
        puppet_collection: ENV.fetch('RELEASE_STREAM', nil),
      }

      install_puppet_agent_on(hosts, opts)
    end
  end

  # make sure install is sane, beaker has already added puppet and ruby
  # to PATH in ~/.ssh/environment
  agents.each do |agent| # rubocop:disable Style/CombinableLoops
    on agent, puppet('--version')
    ruby = ruby_command(agent)
    on agent, "#{ruby} --version"
  end
end
