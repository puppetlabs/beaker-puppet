test_name "Install repositories on target machines..." do

  repositories = options[:install].map do |url|
    extract_repo_info_from(build_git_url(url))
  end

  agents.each_with_index do |host, index|
    on host, "echo #{GitHubSig} >> $HOME/.ssh/known_hosts"

    repositories.each do |repository|
      step "Install #{repository[:name]}"

      # If we're using docker, and we've mounted the puppet directory, let's run
      # tests from there rather than a github repo. In this case, we assume the
      # name of the mount corresponds to the thing we're trying to install.
      #
      #   HOSTS:
      #     hostname-1:
      #       hypervisor: docker
      #       mount_folders:
      #         puppet:
      #           host_path: ~/puppet
      #           container_path: /build/puppet
      #
      if host[:mount_folders]
        mount = host[:mount_folders][repository[:name]]
        repository[:path] = "file://#{mount[:container_path]}"
      end
      repo_dir = host.tmpdir(repository[:name])
      on(host, "chmod 755 #{repo_dir}")

      gem_source = ENV["GEM_SOURCE"] || "https://rubygems.org"

      case repository[:path]
      when /^(git:|https:|git@)/
        sha = ENV['SHA'] || `git rev-parse HEAD`.chomp
        gem_path = ":git => '#{repository[:path]}', :ref => '#{sha}'"
      when /^file:\/\/(.*)/
        gem_path = ":path => '#{$1}'"
      else
        gem_path = repository[:path]
      end
      create_remote_file(host, "#{repo_dir}/Gemfile", <<-END)
source '#{gem_source}'
gem '#{repository[:name]}', #{gem_path}
      END

      case host['platform']
      when /windows/
        # bundle must be passed a Windows style path for a binstubs location
        bindir = host['puppetbindir'].split(':').first
        binstubs_dir = on(host, "cygpath -m \"#{bindir}\"").stdout.chomp
        # note passing --shebang to bundle is not useful because Cygwin
        # already finds the Ruby interpreter OK with the standard shebang of:
        # !/usr/bin/env ruby
        # the problem is a Cygwin style path is passed to the interpreter and this can't be modified:
        # http://cygwin.1069669.n5.nabble.com/Pass-windows-style-paths-to-the-interpreter-from-the-shebang-line-td43870.html
        on host, "cd #{repo_dir} && #{bundle_command(host)} install --system --binstubs '#{binstubs_dir}'"

        # bundler created but does not install batch files to the binstubs dir
        # so we have to manually copy the batch files over
        gemdir = on(host, "#{gem_command(host)} environment gemdir").stdout.chomp
        gembindir = File.join(gemdir, 'bin')
        on host, "cd '#{host['puppetbindir']}' && test -f ./#{repository[:name]}.bat || cp '#{gembindir}/#{repository[:name]}.bat' '#{host['puppetbindir']}/#{repository[:name]}.bat'"
      else
        on host, "cd #{repo_dir} && #{bundle_command(host)} install --system --binstubs #{host['puppetbindir']}"
      end
      puppet_bundler_install_dir ||= on(host, "cd #{repo_dir} && #{bundle_command(host)} show #{repository[:name]}").stdout.chomp
      host.add_env_var('RUBYLIB', File.join(puppet_bundler_install_dir, 'lib'))
    end
  end

  step "Hosts: create environments directory like AIO does" do
    agents.each do |host|
      codedir = host.puppet['codedir']
      on host, "mkdir -p #{codedir}/environments/production/manifests"
      on host, "mkdir -p #{codedir}/environments/production/modules"
      on host, "chmod -R 755 #{codedir}"
    end
  end
end
