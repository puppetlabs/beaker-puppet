case agent['platform']
  when /aix/
    # Bootstrap yum and dependencies
    on(agent, "curl -O http://pl-build-tools.delivery.puppetlabs.net/aix/yum_bootstrap/rpm.rte && installp -acXYgd . rpm.rte all")
    on(agent, "curl http://pl-build-tools.delivery.puppetlabs.net/aix/yum_bootstrap/openssl-1.0.2.1500.tar | tar xvf - && cd openssl-1.0.2.1500 && installp -acXYgd . openssl.base all")
    on(agent, "rpm --rebuilddb && updtvpkg")
    on(agent, "mkdir -p /tmp/yum_bundle && cd /tmp/yum_bundle/ && curl -O http://pl-build-tools.delivery.puppetlabs.net/aix/yum_bootstrap/yum_bundle.tar && tar xvf yum_bundle.tar && rpm -Uvh /tmp/yum_bundle/*.rpm")

    # Use artifactory mirror for AIX toolbox packages
    on(agent, "/usr/bin/sed 's/enabled=1/enabled=0/g' /opt/freeware/etc/yum/yum.conf > tmp.$$ && mv tmp.$$ /opt/freeware/etc/yum/yum.conf")
    on(agent, "echo '[AIX_Toolbox_mirror]\nname=AIX Toolbox local mirror\nbaseurl=https://artifactory.delivery.puppetlabs.net/artifactory/rpm__remote_aix_linux_toolbox/RPMS/ppc/\ngpgcheck=0' > /opt/freeware/etc/yum/repos.d/toolbox-generic-mirror.repo")
    on(agent, "echo '[AIX_Toolbox_noarch_mirror]\nname=AIX Toolbox noarch repository\nbaseurl=https://artifactory.delivery.puppetlabs.net/artifactory/rpm__remote_aix_linux_toolbox/RPMS/noarch/\ngpgcheck=0' > /opt/freeware/etc/yum/repos.d/toolbox-noarch-mirror.repo")
    if agent['platform'] == "aix-6.1-power"
      on(agent, "echo '[AIX_Toolbox_61_mirror]\nname=AIX 61 specific repository\nbaseurl=https://artifactory.delivery.puppetlabs.net/artifactory/rpm__remote_aix_linux_toolbox/RPMS/ppc-6.1/\ngpgcheck=0' > /opt/freeware/etc/yum/repos.d/toolbox-61-mirror.repo")
    elsif agent['platform'] == "aix-7.1-power"
      on(agent, "echo '[AIX_Toolbox_71_mirror]\nname=AIX 71 specific repository\nbaseurl=https://artifactory.delivery.puppetlabs.net/artifactory/rpm__remote_aix_linux_toolbox/RPMS/ppc-7.1/\ngpgcheck=0' > /opt/freeware/etc/yum/repos.d/toolbox-71-mirror.repo")
    elsif agent['platform'] == "aix-7.2-power"
      on(agent, "echo '[AIX_Toolbox_72_mirror]\nname=AIX 72 specific repository\nbaseurl=https://artifactory.delivery.puppetlabs.net/artifactory/rpm__remote_aix_linux_toolbox/RPMS/ppc-7.2/\ngpgcheck=0' > /opt/freeware/etc/yum/repos.d/toolbox-72-mirror.repo")
    end
end
