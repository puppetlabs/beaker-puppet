require 'spec_helper'

class ClassMixedWithDSLHelpers
  include Beaker::DSL::Helpers::HostHelpers
end

describe ClassMixedWithDSLHelpers do
  let(:privatebindir) { 'C:\\Program Files\\Puppet Labs\\Puppet\\bin' }

  context 'when platform is windows and non cygwin' do
    let(:winhost) { make_host('winhost_non_cygwin', { :platform => 'windows',
                                                      :privatebindir => privatebindir,
                                                      :is_cygwin => 'false' }) }

    it 'run the correct ruby_command' do
      expect(subject.ruby_command(winhost)).to eq("cmd /V /C \"set PATH=#{privatebindir};!PATH! && ruby\"")
    end
  end

  context 'when platform is windows and cygwin' do
    let(:winhost) { make_host('winhost', { :platform => Beaker::Platform.new('windows-2016-a64'),
                                           :privatebindir => privatebindir,
                                           :is_cygwin => true }) }

    it 'run the correct ruby_command' do
      expect(subject.ruby_command(winhost)).to eq("env PATH=\"#{privatebindir}:${PATH}\" ruby")
    end
  end
end
