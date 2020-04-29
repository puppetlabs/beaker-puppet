require 'beaker-puppet'

# the version is required on windows
# all versions are required for osx
hosts.each do |host|
  install_puppet_on(host, {
    :version        => ENV['BEAKER_PUPPET_VERSION'] || '5.5.20',
    :puppet_agent_version => ENV['BEAKER_PUPPET_AGENT_VERSION'] || '5.5.20'
  })

  on(host, puppet('resource user puppet ensure=present'))
  on(host, puppet('resource group puppet ensure=present'))
end
