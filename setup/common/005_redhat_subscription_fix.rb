test_name 'Refresh Red Hat 8 subscription repository'

# Only need to run this on Red Hat Enterprise Linux 8 on little-endian PowerPC
skip_test 'Not Red Hat 8 PPCle' if ! hosts.any? { |host| host.platform == 'el-8-ppc64le' }

hosts.each do |host|
  next unless host.platform == 'el-8-ppc64le'

  on(host, '/usr/sbin/subscription-manager repos --disable rhel-8-for-ppc64le-baseos-rpms && /usr/sbin/subscription-manager repos --enable rhel-8-for-ppc64le-baseos-rpms')
end
