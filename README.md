# beaker-puppet: The Puppet-Specific Beaker Library

The purpose of this library is to hold all puppet-specific info & DSL methods.
This includes all helper & installer methods.

It might not be up to that state yet, but that's the goal for this library. If
you see anything puppet-specific that you'd like to pull into this library out
of beaker, please do, we would love any help that you'd like to provide. 

# How Do I Use This?

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
