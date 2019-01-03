test_name "Validate Sign Cert" do
  # 'is_puppetserver' is an option that used to distinguish puppetserver masters
  # from those using passenger, etc., but it is (should be) unused these days.
  # In this case, we're using it as a toggle for whether puppetserver should be
  # installed.
  skip_test 'not testing with puppetserver' unless @options['is_puppetserver']

  sign_agent_certs
end
