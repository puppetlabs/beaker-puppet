require 'beaker'

require 'in_parallel'
require 'beaker-puppet/version'
require 'beaker-puppet/wrappers'

require 'beaker-puppet/helpers/rake_helpers'

[ 'aio', 'foss' ].each do |lib|
  require "beaker-puppet/install_utils/#{lib}_defaults"
end
[ 'windows', 'foss', 'puppet', 'ezbake', 'module' ].each do |lib|
  require "beaker-puppet/install_utils/#{lib}_utils"
end
[ 'tk', 'facter', 'puppet', 'host' ].each do |lib|
  require "beaker-puppet/helpers/#{lib}_helpers"
end

require 'beaker-puppet/install_utils/puppet5'


module BeakerPuppet
  include Beaker::DSL::InstallUtils::FOSSDefaults
  include Beaker::DSL::InstallUtils::AIODefaults

  include Beaker::DSL::InstallUtils::WindowsUtils
  include Beaker::DSL::InstallUtils::PuppetUtils
  include Beaker::DSL::InstallUtils::FOSSUtils
  include Beaker::DSL::InstallUtils::EZBakeUtils
  include Beaker::DSL::InstallUtils::ModuleUtils

  include Beaker::DSL::InstallUtils::Puppet5

  include Beaker::DSL::Helpers::TKHelpers
  include Beaker::DSL::Helpers::FacterHelpers
  include Beaker::DSL::Helpers::PuppetHelpers
  include Beaker::DSL::Helpers::HostHelpers

  include Beaker::DSL::Wrappers
end

# Register the DSL extension
Beaker::DSL.register( BeakerPuppet )
