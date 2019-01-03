test_name "Install Puppet Server" do
  # 'is_puppetserver' is an option that used to distinguish puppetserver masters
  # from those using passenger, etc., but it is (should be) unused these days.
  # In this case, we're using it as a toggle for whether puppetserver should be
  # installed.
  skip_test "not testing with puppetserver" unless @options['is_puppetserver']

  install_puppetserver_on(master,
                          version: ENV['SERVER_VERSION'],
                          release_stream: ENV['RELEASE_STREAM'],
                          nightly_builds_url: ENV['NIGHTLY_BUILDS_URL'],
                          dev_builds_url: ENV['DEV_BUILDS_URL'])
end
