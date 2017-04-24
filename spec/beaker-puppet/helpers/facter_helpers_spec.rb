require 'spec_helper'

class ClassMixedWithDSLHelpers
  include Beaker::DSL::Helpers
  include Beaker::DSL::Wrappers
  include Beaker::DSL::Roles
  include Beaker::DSL::Patterns
  # include Beaker::DSL::Helpers::FacterHelpers
  # include Beaker::DSL::Wrappers
  # include BeakerTestHelpers

  def logger
    RSpec::Mocks::Double.new('logger').as_null_object
  end

end

describe ClassMixedWithDSLHelpers do
  let( :command ){ 'ls' }
  let( :host )   { double.as_null_object }
  let( :result ) { Beaker::Result.new( host, command ) }

  let( :master ) { make_host( 'master',   :roles => %w( master agent default)    ) }
  let( :agent )  { make_host( 'agent',    :roles => %w( agent )           ) }
  let( :custom ) { make_host( 'custom',   :roles => %w( custom agent )    ) }
  let( :dash )   { make_host( 'console',  :roles => %w( dashboard agent ) ) }
  let( :db )     { make_host( 'db',       :roles => %w( database agent )  ) }
  let( :hosts )  { [ master, agent, dash, db, custom ] }

  before :each do
    allow( subject ).to receive( :hosts ).and_return( hosts )
  end

  describe '#fact_on' do
    it 'retrieves a fact on a single host' do
      result.stdout = "family\n"
      expect( subject ).to receive(:facter).with('osfamily',{}).once
      expect( subject ).to receive(:on).and_return(result)

      expect( subject.fact_on('host','osfamily') ).to be === result.stdout.chomp
    end

    it 'chomps correctly when it receives an array of results from #on' do
      result.stdout = "family\n"
      times = hosts.length
      results_array = [result] * times
      chomped_array = [result.stdout.chomp] * times
      allow( subject ).to receive( :on ).and_return( results_array )

      expect( subject.fact_on(hosts,'osfamily') ).to be === chomped_array

    end
  end

  describe '#fact' do
    it 'delegates to #fact_on with the default host' do
      expect( subject ).to receive(:fact_on).with(anything,"osfamily",{}).once
      expect( subject ).to receive(:default)

      subject.fact('osfamily')
    end
  end

end
