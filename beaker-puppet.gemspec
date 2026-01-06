$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'beaker-puppet/version'

Gem::Specification.new do |s|
  s.name        = 'beaker-puppet'
  s.version     = BeakerPuppet::VERSION
  s.authors     = ['Vox Pupuli']
  s.email       = ['voxpupuli@groups.io']
  s.homepage    = 'https://github.com/voxpupuli/beaker-puppet'
  s.summary     = "Beaker's Puppet DSL Extension Helpers!"
  s.description = 'For use for the Beaker acceptance testing tool'
  s.license     = 'Apache-2.0'

  s.required_ruby_version = '>= 2.7', '< 5'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  # Testing dependencies
  s.add_development_dependency 'fakefs', '>= 0.6', '< 3.0'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rspec-its', '~> 1.3'
  s.add_development_dependency 'voxpupuli-rubocop', '~> 3.0'

  # Acceptance Testing Dependencies
  s.add_development_dependency 'beaker-vmpooler', '~> 1.4'

  # Run time dependencies
  s.add_runtime_dependency 'beaker', '>= 5.0', '< 7'
  s.add_runtime_dependency 'oga', '~> 3.4'
end
