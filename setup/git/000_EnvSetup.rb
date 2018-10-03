test_name "Setup environment"

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

# We need to be able override which tar we use on solaris
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

step "Install puppet-runtime" do
  step 'grab the latest runtime tag'
  runtime_dir = Dir.mktmpdir('puppet-runtime')
  `git clone --depth 1 git@github.com:puppetlabs/puppet-runtime.git #{runtime_dir}`
  Dir.chdir runtime_dir do
    runtime_tag = `git describe --first-parent --abbrev=0`.chomp
  end

  step 'construct the runtime url'
  dev_builds_url = ENV['DEV_BUILDS_URL'] || 'http://builds.delivery.puppetlabs.net'
  runtime_url = "#{dev_builds_url}/puppet-runtime/#{runtime_tag}/artifacts/"

  step 'construct the tarball name'
  branch = '5.5.x'
  runtime_prefix = "agent-runtime-#{branch}-#{runtime_tag}."
  runtime_suffix = ".tar.gz"

  agents.each do |host|
    platform_tag = host['packaging_platform']
    if platform_tag =~ /windows/
      # the windows version is hard coded to 2012r2. Unfortunately,
      # `host['packaging_platform']` is hard coded to 2012, so we have to add the
      # `r2` on our own.
      platform, version, arch = platform_tag.split('-')
      platform_tag = "#{platform}-#{version}r2-#{arch}"
    end
    tarball_name = runtime_prefix + platform_tag + runtime_suffix

    on host, "curl -O #{runtime_url}#{tarball_name}"

    case host['platform']
    when /windows/
      on host, "gunzip -c #{tarball_name} | tar -k -C /cygdrive/c/ -xf -"
      on host, "chmod 755 /cygdrive/c/ProgramFiles64Folder/PuppetLabs/Puppet/sys/ruby/bin/*"
      host.add_env_var('PATH', '/cygdrive/c/ProgramFiles64Folder/PuppetLabs/Puppet/sys/ruby/bin')
    when /osx/
      on host, "tar -xzf #{tarball_name}"
      on host, "for d in opt var private; do rsync -ka \"${d}/\" \"/${d}/\"; done"
    else
      on host, "gunzip -c #{tarball_name} | #{tar} -k -C / -xf -"
    end
  end
end

step "Install bundler"

# Only configure gem mirror after Ruby has been installed, but before any gems are installed.
configure_gem_mirror(agents)

agents.each do |host|
  on host, "#{gem_command(host)} install bundler --no-ri --no-rdoc"
end
