test_name "Install Puppet Server" do
  skip_test "not testing with puppetserver" unless @options['is_puppetserver']

  opts = {
    :version => ENV['SERVER_VERSION'],
    :release_stream => ENV['RELEASE_STREAM'],
    :nightly_builds_url => ENV['NIGHTLY_BUILDS_URL'],
    :dev_builds_url => ENV['DEV_BUILDS_URL']
  }
  unless master['use_existing_container']
    install_puppetserver_on(master, opts)
  end
end
