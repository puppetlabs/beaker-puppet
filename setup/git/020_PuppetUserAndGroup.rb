test_name 'Puppet User and Group' do
  hosts.each do |host|
    next if host['use_existing_container']
    step "ensure puppet user and group added to all nodes because this is what the packages do" do
      on host, puppet("resource user puppet ensure=present")
    end
  end
end
