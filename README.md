# beaker-puppet: The Puppet-Specific Beaker Library

The purpose of this library is to hold all puppet-specific info & DSL methods.
This includes all helper & installer methods.

It might not be up to that state yet, but that's the goal for this library. If
you see anything puppet-specific that you'd like to pull into this library out
of beaker, please do, we would love any help that you'd like to provide.

# How Do I Use This?

## With Beaker 3.x

This library is included as a dependency of Beaker 3.x versions and is automatically included, so there's nothing to do.

## With Beaker 4.x

As of Version 1.0 of `beaker-puppet`, the minimum supported version of beaker is Version 4.0. If you use `ENV['BEAKER_VERSION']`, you will have to ensure that this is compatible, and that if you are using a local Git repository it is up to date.

As of beaker 4.0, all hypervisor and DSL extension libraries have been removed and are no longer dependencies. In order to use a specific hypervisor or DSL extension library in your project, you will need to include them alongside Beaker in your Gemfile or project.gemspec. E.g.

~~~ruby
# Gemfile
gem 'beaker', '~>4.0'
gem 'beaker-puppet', '~>1.0'
# project.gemspec
s.add_runtime_dependency 'beaker', '~>4.0'
s.add_runtime_dependency 'beaker-puppet', '~>1.0'
~~~

For DSL Extension Libraries, you must also ensure that you `require` the library in your test files. You can do this manually in individual test files or in a test helper (if you have one). You can [use `Bundler.require()`](https://bundler.io/v1.16/guides/groups.html) to require the library automatically.

### Right Now? (beaker 3.x)

At this point, beaker-puppet is included in beaker, so you don't have to _do_
anything to get the methods in this library.

You can use these methods in a test by referencing them by name without
qualifications, as they're included in the beaker DSL by default.

### In beaker's Next Major Version? (beaker 4.x)

In beaker's next major version, the requirement for beaker-puppet will be pulled
from that repo. When that happens, then the usage pattern will change. In order
to use this then, you'll need to include beaker-puppet as a dependency right
next to beaker itself.

Once you've done that & installed the gems, in your test, you'll have to
```ruby
require 'beaker-puppet'
```

Doing this will include (automatically) the beaker-puppet DSL methods in the
beaker DSL. Then you can call beaker-puppet methods, exactly as you did before.

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

# Contributing

Please refer to puppetlabs/beaker's [contributing](https://github.com/puppetlabs/beaker/blob/master/CONTRIBUTING.md) guide.

# Releasing

To release the gem, update the version at `lib/beaker-puppet/version.rb` then tag
the repo with the corresponding version. Once tagged, a Github Action will
trigger which builds and publishes the gem.
