test_name "Validate Sign Cert" do
  skip_test 'not testing with puppetserver' unless @options['is_puppetserver']
  hostname = on(master, 'facter hostname').stdout.strip
  fqdn = on(master, 'facter fqdn').stdout.strip

  if master.use_service_scripts?
    step "Ensure puppet is stopped"
    # Passenger, in particular, must be shutdown for the cert setup steps to work,
    # but any running puppet master will interfere with webrick starting up and
    # potentially ignore the puppet.conf changes.
    on(master, puppet('resource', 'service', master['puppetservice'], "ensure=stopped"))
  end

  step "Clear SSL on all hosts"
  hosts.each do |host|
    ssldir = on(host, puppet('agent --configprint ssldir')).stdout.chomp
    # preserve permissions for master's ssldir so puppetserver can read it
    on(host, "rm -rf '#{ssldir}/*'")
  end

  step "Start puppetserver" do
    master_opts = {
      :main => {
        :dns_alt_names => "puppet,#{hostname},#{fqdn}",
      },
    }

    on master, 'puppetserver ca generate'
    with_puppet_running_on(master, master_opts) do
      agents.each do |agent|
        next if agent == master

        step "Agents: Run agent --test first time to gen CSR"
        on agent, puppet("agent --test --server #{master}"), :acceptable_exit_codes => [1]
      end

      # Sign all waiting agent certs
      step "Server: sign all agent certs"
      on master, 'puppetserver ca sign --all', :acceptable_exit_codes => [0, 24]

      step "Agents: Run agent --test second time to obtain signed cert"
      on agents, puppet("agent --test --server #{master}"), :acceptable_exit_codes => [0,2]
    end
  end
end
