require 'stringify-hash'
require 'in_parallel'
require 'beaker-puppet/helpers'
require 'beaker-puppet/version'
require 'beaker-puppet/wrappers'

[ 'foss', 'puppet', 'ezbake', 'module' ].each do |lib|
  require "beaker-puppet/install_utils/#{lib}_utils"
end
[ 'tk', 'facter', 'puppet' ].each do |lib|
  require "beaker-puppet/helpers/#{lib}_helpers"
end


module BeakerPuppet
  module InstallUtils
    include Beaker::DSL::InstallUtils::PuppetUtils
    include Beaker::DSL::InstallUtils::FOSSUtils
    include Beaker::DSL::InstallUtils::EZBakeUtils
    include Beaker::DSL::InstallUtils::ModuleUtils
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
# # Then we have to re-include our amended DSL in the TestCase,
# # because in general, the DSL is included in TestCase far
# # before test files are executed, so our amendments wouldn't
# # come through otherwise
# include Beaker::DSL
