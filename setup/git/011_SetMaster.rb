test_name 'Hosts: create basic puppet.conf' do
  skip_test 'not testing with puppetserver' unless @options['is_puppetserver']
  hosts.each do |host|
    confdir = host.puppet['confdir']
    on host, "mkdir -p #{confdir}"
    puppetconf = File.join(confdir, 'puppet.conf')

    if host['roles'].include?('agent')
      on host, "echo '[agent]' > '#{puppetconf}' && " +
               "echo server=#{master} >> '#{puppetconf}'"
    else
      on host, "touch '#{puppetconf}'"
    end
  end
end
