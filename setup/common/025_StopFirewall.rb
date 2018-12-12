test_name "Stop firewall" do
  skip_test 'not testing with puppetserver' unless @options['is_puppetserver']
  stop_firewall_with_puppet_on(hosts)
end
