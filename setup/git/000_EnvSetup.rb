test_name "Setup environment"

require 'json'
require 'open-uri'

step 'Configure paths' do
  add_aio_defaults_on(hosts)
  add_puppet_paths_on(hosts)
end

step "Install git and tar"
PACKAGES = {
  :redhat => ['git'],
  :debian => [
    ['git', 'git-core'],
  ],
  :solaris_10 => [
    'coreutils',
    'git',
    'gtar',
  ],
  :windows => ['git'],
  :sles => ['git'],
}

# We need to be able override which tar we use on solaris, which we call later
# when we unpack the puppet-runtime archive
tar = 'tar'

agents.each do |host|
  case host['platform']
  when /solaris/
    tar = 'gtar'
    if host['platform'] =~ /11/
      # The file allows us to non-interactively install these packages with
      # pkgutil on solaris 11. Solaris 10 does this as a part of the
      # `install_packages_on` method in beaker. Since we install packages for
      # solaris 11 using pkg by default, we can't use that method for sol11.
      # We have to override it so that we can get git from opencws, as it has
      # the updated ssl certs we need to access github repos.
      create_remote_file host, "/root/shutupsolaris", <<-END
mail=
# Overwrite already installed instances
instance=overwrite
# Do not bother checking for partially installed packages
partial=nocheck
# Do not bother checking the runlevel
runlevel=nocheck
# Do not bother checking package dependencies (We take care of this)
idepend=nocheck
rdepend=nocheck
# DO check for available free space and abort if there isn't enough
space=quit
# Do not check for setuid files.
setuid=nocheck
# Do not check if files conflict with other packages
conflict=nocheck
# We have no action scripts.  Do not check for them.
action=nocheck
# Install to the default base directory.
basedir=default
        END
      on host, 'pkgadd -d http://get.opencsw.org/now -a /root/shutupsolaris -n all'
      on host, '/opt/csw/bin/pkgutil -U all'
      on host, '/opt/csw/bin/pkgutil -y -i git'
      on host, '/opt/csw/bin/pkgutil -y -i gtar'
    end
    host.add_env_var('PATH', '/opt/csw/bin')
  end
end

install_packages_on(agents, PACKAGES, :check_if_exists => true)

step "Unpack puppet-runtime" do
  need_to_run = false
  agents.each do |host|
    # we only need to unpack the runtime if the host doesn't already have runtime
    # and if it's a not an existing container
    need_to_run ||= (!host['has_runtime'] && !host['use_existing_container'])
  end

  if need_to_run
    dev_builds_url = ENV['DEV_BUILDS_URL'] || 'http://builds.delivery.puppetlabs.net'
    branch = ENV['RUNTIME_BRANCH'] || 'master'

    # We want to grab whatever tag has been promoted most recently into the branch
    # of puppet-agent that corresponds to whatever component we're working on.
    # This will allow us to get the latest runtime package that has passed tests.
    runtime_json = "https://raw.githubusercontent.com/puppetlabs/puppet-agent/#{branch}/configs/components/puppet-runtime.json"
    runtime_tag = JSON.load(open(runtime_json))['version']

    runtime_url = "#{dev_builds_url}/puppet-runtime/#{runtime_tag}/artifacts/"

    runtime_prefix = "agent-runtime-#{branch}-#{runtime_tag}."
    runtime_suffix = ".tar.gz"

    agents.each do |host|
      next if host['has_runtime'] || host['use_existing_container']

      platform_tag = host['packaging_platform']
      if platform_tag =~ /windows/
        # the windows version is hard coded to `2012r2`. Unfortunately,
        # `host['packaging_platform']` is hard coded to `2012`, so we have to add
        # the `r2` on our own.
        platform, version, arch = platform_tag.split('-')
        platform_tag = "#{platform}-#{version}r2-#{arch}"
      end
      tarball_name = runtime_prefix + platform_tag + runtime_suffix

      on host, "curl -Of #{runtime_url}#{tarball_name}"

      case host['platform']
      when /windows/
        on host, "gunzip -c #{tarball_name} | tar -k -C /cygdrive/c/ -xf -"

        if arch == 'x64'
          program_files = 'ProgramFiles64Folder'
        else
          program_files = 'ProgramFilesFolder'
        end
        if branch == '5.5.x'
          bindir = "/cygdrive/c/#{program_files}/PuppetLabs/Puppet/sys/ruby/bin"
        else
          bindir = "/cygdrive/c/#{program_files}/PuppetLabs/Puppet/puppet/bin"
        end
        on host, "chmod 755 #{bindir}/*"

        # Because the runtime archive for windows gets installed in a non-standard
        # directory (ProgramFiles64Folder), we need to add it to the path here
        # rather than rely on `host['privatebindir']` like we can for other
        # platforms
        host.add_env_var('PATH', bindir)
      when /osx/
        on host, "tar -xzf #{tarball_name}"
        on host, "for d in opt var private; do rsync -ka \"${d}/\" \"/${d}/\"; done"
      else
        on host, "gunzip -c #{tarball_name} | #{tar} -k -C / -xf -"
      end
    end
  end
end

step "Install bundler" do
  # Only configure gem mirror after Ruby has been installed, but before any gems are installed.
  configure_gem_mirror(agents)

  agents.each do |host|
    on host, "#{gem_command(host)} install bundler --no-document"
  end
end
