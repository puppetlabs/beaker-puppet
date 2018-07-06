test_name "Install packages and repositories on target machines..." do
  repositories = options[:install].map do |url|
    extract_repo_info_from(build_git_url(url))
  end

  hosts.each_with_index do |host, index|
    on host, "echo #{GitHubSig} >> $HOME/.ssh/known_hosts"

    repositories.each do |repository|
      step "Install #{repository[:name]}"
      if repository[:path] =~ /^file:\/\/(.+)$/
        on host, "test -d #{SourcePath} || mkdir -p #{SourcePath}"
        source_dir = $1
        checkout_dir = "#{SourcePath}/#{repository[:name]}"
        on host, "rm -f #{checkout_dir}" # just the symlink, do not rm -rf !
        on host, "ln -s #{source_dir} #{checkout_dir}"
        on host, "cd #{checkout_dir} && if [ -f install.rb ]; then ruby ./install.rb ; else true; fi"
      else
        puppet_dir = host.tmpdir('puppet')
        on(host, "chmod 755 #{puppet_dir}")

        host.add_env_var('BUNDLE_GEMFILE', File.join(puppet_dir, 'Gemfile'))

        sha = ENV['SHA'] || `git rev-parse HEAD`.chomp
        gem_source = ENV["GEM_SOURCE"] || "https://rubygems.org"
        create_remote_file(host, "#{puppet_dir}/Gemfile", <<END)
source '#{gem_source}'
gem '#{repository[:name]}', :git => '#{repository[:path]}', :ref => '#{sha}'
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
          on host, "cd #{puppet_dir} && #{bundle_command(host)} install --system --binstubs '#{binstubs_dir}'"

          # bundler writes puppet and facter, but not puppet.bat
          on host, "cd '#{bindir}' && test -f ./puppet.bat || cp ./puppet ./puppet.bat"
          on host, "cd '#{bindir}' && test -f ./facter.bat || cp ./facter ./facter.bat"
          on host, "cd '#{bindir}' && test -f ./hiera.bat || cp ./hiera ./hiera.bat"
        else
          on host, "cd #{puppet_dir} && #{bundle_command(host)} install --system --binstubs #{host['puppetbindir']}"
        end
        puppet_bundler_install_dir = on(host, "cd #{puppet_dir} && #{bundle_command(host)} show puppet").stdout.chomp

        # install.rb should also be called from the Puppet gem install dir
        # this is required for the puppetres.dll event log dll on Windows
        on host, "cd #{puppet_bundler_install_dir} && if [ -f install.rb ]; then ruby ./install.rb ; else true; fi"
      end
    end
  end

  step "Hosts: create environments directory like AIO does" do
    hosts.each do |host|
      codedir = host.puppet['codedir']
      on host, "mkdir -p #{codedir}/environments/production/manifests"
      on host, "mkdir -p #{codedir}/environments/production/modules"
      on host, "chmod -R 755 #{codedir}"
    end
  end
end
