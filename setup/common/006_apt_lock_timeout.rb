test_name 'Stop the background apt upgrader and make apt wait for the dpkg lock'

# Debian and Ubuntu images ship unattended-upgrades. systemd starts it from two
# timers, apt-daily.timer (06:00 and 18:00 UTC plus a random delay of up to
# 12 hours) and apt-daily-upgrade.timer (06:00 UTC plus up to 60 minutes). Both
# end up running unattended-upgrade, which holds the dpkg lock while it works.
# A test that installs or removes a package at that moment fails at once:
#
#   E: Could not get lock /var/lib/dpkg/lock-frontend. It is held by process
#   1234 (unattended-upgr)
#
# Nothing a test does starts the upgrader; only the timers do. So:
#
# 1. Mask the timers (and the unattended-upgrades service) before any package
#    management happens, so the upgrader cannot start again during the suite.
#    This removes the cause.
# 2. Keep a lock timeout for the run that may already be in progress when this
#    step executes: masking does not release a lock that is already held, and we
#    do not kill a running dpkg transaction. DPkg::Lock::Timeout makes every
#    apt-get run on the host, including the ones puppet's apt provider starts,
#    wait for the lock instead of failing. Versions of apt that do not know the
#    option ignore it.
#
# On hosts whose hypervisor is 'none', 000-delete-puppet-when-none.rb runs before
# this step and uses the package manager, so it can still meet a running
# upgrader. The timeout covers that case.
APT_UPGRADER_UNITS = %w[apt-daily.timer apt-daily-upgrade.timer unattended-upgrades.service].freeze
DPKG_LOCK_TIMEOUT_FILE = '/etc/apt/apt.conf.d/99-beaker-dpkg-lock-timeout'.freeze
DPKG_LOCK_TIMEOUT = 300 # seconds

apt_hosts = hosts.select { |host| host.platform =~ /^(debian|ubuntu)-/ }
skip_test 'No Debian or Ubuntu hosts' if apt_hosts.empty?

apt_hosts.each do |host|
  # /run/systemd/system exists only when systemd is the running init; without it
  # there are no timers to mask (for example in a plain container).
  systemd_running = on(host, 'test -d /run/systemd/system', accept_all_exit_codes: true).exit_code.zero?
  on(host, "systemctl mask --now #{APT_UPGRADER_UNITS.join(' ')}") if systemd_running

  create_remote_file(host, DPKG_LOCK_TIMEOUT_FILE, "DPkg::Lock::Timeout \"#{DPKG_LOCK_TIMEOUT}\";\n")
  # create_remote_file copies the file as 0600; apt run by other users must be able to read it too.
  on(host, "chmod 0644 #{DPKG_LOCK_TIMEOUT_FILE}")
end
