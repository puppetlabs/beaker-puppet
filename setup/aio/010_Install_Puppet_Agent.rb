extend BeakerPuppet::Install::Puppet5
extend Beaker::DSL::InstallUtils::FOSSUtils

test_name "Install Packages" do

  dev_builds_url  = ENV['DEV_BUILDS_URL'] || 'http://builds.delivery.puppetlabs.net'

  step "Install puppet-agent..." do
    sha = ENV['SHA']
    install_from_build_data_url('puppet-agent', "#{dev_builds_url}/puppet-agent/#{sha}/artifacts/#{sha}.yaml", hosts)
  end

  # make sure install is sane, beaker has already added puppet and ruby
  # to PATH in ~/.ssh/environment
  agents.each do |agent|
    on agent, puppet('--version')
    ruby = ruby_command(agent)
    on agent, "#{ruby} --version"
  end
end
