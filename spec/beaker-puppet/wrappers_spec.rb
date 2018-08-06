require 'spec_helper'

class ClassMixedWithDSLWrappers
  include Beaker::DSL::Wrappers
end

describe ClassMixedWithDSLWrappers do
  let(:empty_opts) { {'ENV' => {}, :cmdexe => true } }

  describe '#facter' do
    it 'should split out the options and pass "facter" as first arg to Command' do
      expect( Beaker::Command ).to receive( :new ).
        with('facter', [ '-p' ], empty_opts)
      subject.facter( '-p' )
    end
  end

  describe '#cfacter' do
    it 'should split out the options and pass "cfacter" as first arg to Command' do
      expect( Beaker::Command ).to receive( :new ).
        with('cfacter', [ '-p' ], empty_opts)
      subject.cfacter( '-p' )
    end
  end

  describe 'deprecated puppet wrappers' do
    %w( resource doc kick cert apply master agent filebucket ).each do |sub|
      it "#{sub} delegates the proper info to #puppet" do
        expect( subject ).to receive( :puppet ).with( sub, 'blah' )
        subject.send( "puppet_#{sub}", 'blah')
      end
    end
  end
end
