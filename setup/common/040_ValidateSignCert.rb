test_name "Validate Sign Cert" do
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
    on(host, "rm -rf '#{ssldir}'")
  end

  step "Master: Start Puppet Master" do
    master_opts = {
      :main => {
        :dns_alt_names => "puppet,#{hostname},#{fqdn}",
      },
      :__service_args__ => {
        # apache2 service scripts can't restart if we've removed the ssl dir
        :bypass_service_script => true,
      },
    }
    with_puppet_running_on(master, master_opts) do

      hosts.each do |host|
        next if host['roles'].include? 'master'

        step "Agents: Run agent --test first time to gen CSR"
        on host, puppet("agent --test --server #{master}"), :acceptable_exit_codes => [1]
      end

      # Sign all waiting certs
      step "Master: sign all certs"
      on master, puppet("cert --sign --all"), :acceptable_exit_codes => [0,24]

      step "Agents: Run agent --test second time to obtain signed cert"
      on agents, puppet("agent --test --server #{master}"), :acceptable_exit_codes => [0,2]
    end
  end
end
