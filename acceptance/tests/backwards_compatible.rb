test_name 'backwards compatible test' do

  step 'calls the new FOSSUtils even if I require & include the old path' do
    require 'beaker/dsl/install_utils/foss_utils'
    assert( !Beaker::DSL::InstallUtils::FOSSUtils::SourcePath.nil? )
    assert( Beaker::DSL::InstallUtils::FOSSUtils.method_defined?(:lookup_in_env) )
  end

  step 'require old Helpers path, get helpers from new location' do
    require 'beaker/dsl/helpers/puppet_helpers'
    assert( Beaker::DSL::Helpers::PuppetHelpers.method_defined?(:puppet_user) )
    assert( Beaker::DSL::Helpers::PuppetHelpers.method_defined?(:resolve_hostname_on) )
  end

  step 'require old Helpers module, get from new location' do
    require 'beaker/dsl/helpers'
    assert( Beaker::DSL::Helpers.is_a?( Module ) )
  end
end