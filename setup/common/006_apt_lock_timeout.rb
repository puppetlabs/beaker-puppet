test_name 'Make apt wait for the dpkg lock'

# Debian and Ubuntu images ship unattended-upgrades, which can hold the dpkg
# lock for minutes while tests install or remove packages. By default apt-get
# gives up at once:
#
#   E: Could not get lock /var/lib/dpkg/lock-frontend. It is held by process
#   1234 (unattended-upgr)
#
# so any test that manages a package with puppet fails at random. Tell apt to
# wait for the lock instead. This applies to every apt-get run on the host,
# including the ones puppet's apt provider starts. Versions of apt that do not
# know the option ignore it.
DPKG_LOCK_TIMEOUT_FILE = '/etc/apt/apt.conf.d/99-beaker-dpkg-lock-timeout'.freeze
DPKG_LOCK_TIMEOUT = 300 # seconds

apt_hosts = hosts.select { |host| host.platform =~ /^(debian|ubuntu)-/ }
skip_test 'No Debian or Ubuntu hosts' if apt_hosts.empty?

apt_hosts.each do |host|
  create_remote_file(host, DPKG_LOCK_TIMEOUT_FILE, "DPkg::Lock::Timeout \"#{DPKG_LOCK_TIMEOUT}\";\n")
  # create_remote_file copies the file as 0600; apt run by other users must be able to read it too.
  on(host, "chmod 0644 #{DPKG_LOCK_TIMEOUT_FILE}")
end
