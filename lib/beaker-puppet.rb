require 'stringify-hash'
require 'in_parallel'
require 'beaker-puppet/version'
require 'beaker-puppet/wrappers'

[ 'aio', 'foss' ].each do |lib|
  require "beaker-puppet/install_utils/#{lib}_defaults"
end
[ 'foss', 'puppet', 'ezbake', 'module' ].each do |lib|
  require "beaker-puppet/install_utils/#{lib}_utils"
end
[ 'tk', 'facter', 'puppet' ].each do |lib|
  require "beaker-puppet/helpers/#{lib}_helpers"
end

require 'beaker-puppet/install_utils/puppet5'


module BeakerPuppet
  module InstallUtils
    include Beaker::DSL::InstallUtils::FOSSDefaults
    include Beaker::DSL::InstallUtils::AIODefaults

    include Beaker::DSL::InstallUtils::PuppetUtils
    include Beaker::DSL::InstallUtils::FOSSUtils
    include Beaker::DSL::InstallUtils::EZBakeUtils
    include Beaker::DSL::InstallUtils::ModuleUtils

    include BeakerPuppet::Install::Puppet5
  end

  module Helpers
    include Beaker::DSL::Helpers::TKHelpers
    include Beaker::DSL::Helpers::FacterHelpers
    include Beaker::DSL::Helpers::PuppetHelpers
  end

  include Beaker::DSL::Wrappers
end


# # Boilerplate DSL inclusion mechanism:
# # First we register our module with the Beaker DSL
# Beaker::DSL.register( Beaker::DSL::Puppet )
#
# # Modules added into a module which has previously been included are not
# # retroactively included in the including class.
# #
# # https://github.com/adrianomitre/retroactive_module_inclusion
# Beaker::TestCase.class_eval { include Beaker::DSL }
