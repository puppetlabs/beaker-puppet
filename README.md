# beaker-puppet: The Puppet-Specific Beaker Library

[![License](https://img.shields.io/github/license/voxpupuli/beaker-puppet.svg)](https://github.com/voxpupuli/beaker-puppet/blob/master/LICENSE)
[![Test](https://github.com/voxpupuli/beaker-puppet/actions/workflows/test.yml/badge.svg)](https://github.com/voxpupuli/beaker-puppet/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/voxpupuli/beaker-puppet/branch/master/graph/badge.svg?token=Mypkl78hvK)](https://codecov.io/gh/voxpupuli/beaker-puppet)
[![Release](https://github.com/voxpupuli/beaker-puppet/actions/workflows/release.yml/badge.svg)](https://github.com/voxpupuli/beaker-puppet/actions/workflows/release.yml)
[![RubyGem Version](https://img.shields.io/gem/v/beaker-puppet.svg)](https://rubygems.org/gems/beaker-puppet)
[![RubyGem Downloads](https://img.shields.io/gem/dt/beaker-puppet.svg)](https://rubygems.org/gems/beaker-puppet)
[![Donated by Puppet Inc](https://img.shields.io/badge/donated%20by-Puppet%20Inc-fb7047.svg)](#transfer-notice)

The purpose of this library is to hold all puppet-specific info & DSL methods.
This includes all helper & installer methods.

It might not be up to that state yet, but that's the goal for this library. If
you see anything puppet-specific that you'd like to pull into this library out
of beaker, please do, we would love any help that you'd like to provide.

# How Do I Use This?

You will need to include beaker-puppet alongside Beaker in your Gemfile or project.gemspec. E.g.

```ruby
# Gemfile
gem 'beaker', '~>4.0'
gem 'beaker-puppet', '~>1.0'
# project.gemspec
s.add_runtime_dependency 'beaker', '~>4.0'
s.add_runtime_dependency 'beaker-puppet', '~>1.0'
```

For DSL Extension Libraries, you must also ensure that you `require` the
library in your test files. You can do this manually in individual test files
or in a test helper (if you have one). You can [use
`Bundler.require()`](https://bundler.io/v1.16/guides/groups.html) to require
the library automatically. To explicitly require it:

```ruby
require 'beaker-puppet'
```

Doing this will include (automatically) the beaker-puppet DSL methods in the
beaker DSL. Then you can call beaker-puppet methods, exactly as you did before.

## Running Puppet in debug mode

When using `apply_manifest` to run Puppet, it is common that you need debug
output. To achieve this, the debug option can be passed.

```ruby
apply_manifest_on(host, manifest, { debug: true })
```

This has the downside that Puppet always runs in debug mode, which is very
verbose. Of course you can modify the spec, but that's tedious. An easier
alternative is to use the environment variable `BEAKER_PUPPET_DEBUG`.

```sh
BEAKER_PUPPET_DEBUG=1 rspec spec/acceptance/my_spec.rb
```

# How Do I Test This?

### Unit / Spec Testing

You can run the spec testing using our rake task `test:spec:run`. You can also run
`rspec` directly. If you'd like to see a coverage report, then you can run the
`test:spec:coverage` rake task.

### Acceptance Testing

Acceptance testing can be run using the `acceptance` rake test namespace. For
instance, to test using our package installation, you can run the
`acceptance:pkg` task.

Note in the above rake tasks that there are some environment variables that you
can use to customize your run. For specifying your System Under Test (SUT)
environment, you can use `BEAKER_HOSTS`, passing a file path to a beaker hosts
file, or you can provide a beaker-hostgenerator value to the `TEST_TARGET`
environment variable. You can also specify the tests that get executed with the
`TESTS` environment variable.

## Transfer Notice

This plugin was originally authored by [Puppet Inc](http://puppet.com).
The maintainer preferred that Puppet Community take ownership of the module for future improvement and maintenance.
Existing pull requests and issues were transferred over, please fork and continue to contribute here.

Previously: https://github.com/puppetlabs/beaker

## License

This gem is licensed under the Apache-2 license.

## Release information

To make a new release, please do:
* update the version in `lib/beaker-puppet/version.rb`
* Install gems with `bundle install --with release --path .vendor`
* generate the changelog with `bundle exec rake changelog`
* Check if the new version matches the closed issues/PRs in the changelog
* Create a PR with it
* After it got merged, push a tag. GitHub actions will do the actual release to rubygems and GitHub Packages
