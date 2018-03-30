test_name "Ensure the master is running"

on(master, puppet('resource', 'service', master['puppetservice'], "ensure=running", "enable=true"))
