test_name 'Install Puppet Server' do
  skip_test 'not testing with puppetserver' unless @options['is_puppetserver']

  opts = {
    version: ENV.fetch('SERVER_VERSION', nil),
    release_stream: ENV.fetch('RELEASE_STREAM', nil),
    nightly_builds_url: ENV.fetch('NIGHTLY_BUILDS_URL', nil),
    dev_builds_url: ENV.fetch('DEV_BUILDS_URL', nil),
  }
  install_puppetserver_on(master, opts) unless master['use_existing_container']
end
