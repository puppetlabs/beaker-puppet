require 'beaker/dsl/install_utils/foss_defaults'

module BeakerPuppet
  module Install
    module Puppet5

      include Beaker::DSL::InstallUtils::FOSSDefaults

      # grab build json from the builds server
      #
      # @param [String] sha_yaml_url URL to the <SHA>.yaml file containing the
      #    build details
      #
      # @return [Hash{String=>String}] build json parsed into a ruby hash
      def fetch_build_details(sha_yaml_url)
        dst_folder          = Dir.mktmpdir
        sha_yaml_filename   = File.basename(  sha_yaml_url )
        sha_yaml_folder_url = File.dirname(   sha_yaml_url )

        sha_yaml_file_local_path = fetch_http_file(
          sha_yaml_folder_url,
          sha_yaml_filename,
          dst_folder
        )
        file_hash = YAML.load_file( sha_yaml_file_local_path )

        return sha_yaml_folder_url, file_hash[:platform_data]
      end

      # gets the artifact & repo_config URLs for this host in the build
      #
      # @param [Host] host Host to get artifact URL for
      # @param [Hash] build_details Details of the build in a hash
      # @param [String] build_url URL to the build
      #
      # @return [String, String] URL to the build artifact, URL to the repo_config
      #   (nil if there is no repo_config for this platform for this build)
      def host_urls(host, build_details, build_url)
        packaging_platform = host[:packaging_platform]
        if packaging_platform.nil?
          message = <<-EOF
            :packaging_platform not provided for host '#{host}', platform '#{host[:platform]}'
            :packaging_platform should be the platform-specific key from this list:
              #{ build_details.keys }
          EOF
          fail_test( message )
        end

        logger.debug("Platforms available for this build:")
        logger.debug("#{ build_details.keys }")
        logger.debug("PLATFORM SPECIFIC INFO for #{host} (packaging name '#{packaging_platform}'):")
        packaging_data = build_details[packaging_platform]
        logger.debug("- #{ packaging_data }, isnil? #{ packaging_data.nil? }")
        if packaging_data.nil?
          message = <<-EOF
            :packaging_platform '#{packaging_platform}' for host '#{host}' not in build details
            :packaging_platform should be the platform-specific key from this list:
              #{ build_details.keys }
          EOF
          fail_test( message )
        end

        artifact_buildserver_path   = packaging_data[:artifact]
        repoconfig_buildserver_path = packaging_data[:repo_config]
        fail_test('no artifact_buildserver_path found') if artifact_buildserver_path.nil?

        artifact_url    = "#{build_url}/#{artifact_buildserver_path}"
        repoconfig_url  = "#{build_url}/#{repoconfig_buildserver_path}" unless repoconfig_buildserver_path.nil?
        artifact_url_correct = link_exists?( artifact_url )
        logger.debug("- artifact url: '#{artifact_url}'. Exists? #{artifact_url_correct}")
        fail_test('artifact url built incorrectly') if !artifact_url_correct

        return artifact_url, repoconfig_url
      end

      # install build artifact on the given host
      #
      # @param [Host] host Host to install artifact on
      # @param [String] artifact_url URL of the project install artifact
      # @param [String] project_name Name of project for artifact. Needed for OSX installs
      #
      # @return nil
      def install_artifact_on(host, artifact_url, project_name)
        variant, version, _, _ = host[:platform].to_array
        case variant
        when 'eos'
          host.get_remote_file(artifact_url)
          onhost_package_file = File.basename(artifact_url)
          # TODO Will be refactored into {Beaker::Host#install_local_package}
          #   immediately following this work. The release timing makes it
          #   necessary to have this here separately for a short while
          host.install_from_file(onhost_package_file)
        when 'solaris'
          artifact_filename = File.basename(artifact_url)
          artifact_folder = File.dirname(artifact_url)
          fetch_http_file(artifact_folder, artifact_filename, '.')
          onhost_package_dir = host.tmpdir('puppet_installer')
          scp_to host, artifact_filename, onhost_package_dir
          onhost_package_file = "#{onhost_package_dir}/#{artifact_filename}"
          host.install_local_package(onhost_package_file, '.')
        when 'osx'
          on host, "curl -O #{artifact_url}"
          onhost_package_file = "#{project_name}*"
          host.install_local_package(onhost_package_file)
        when 'windows'
          if project_name == 'puppet-agent'
            install_msi_on(host, artifact_url)
          else
            generic_install_msi_on(host, artifact_url)
          end
        when 'aix'
          artifact_filename = File.basename(artifact_url)
          artifact_folder = File.dirname(artifact_url)
          fetch_http_file(artifact_folder, artifact_filename, '.')
          onhost_package_dir = host.tmpdir('puppet_installer')
          scp_to host, artifact_filename, onhost_package_dir
          onhost_package_file = "#{onhost_package_dir}/#{artifact_filename}"

          # TODO Will be refactored into {Beaker::Host#install_local_package}
          #   immediately following this work. The release timing makes it
          #   necessary to have this here seperately for a short while
          # NOTE: the AIX 7.1 package will only install on 7.2 with
          # --ignoreos. This is a bug in package building on AIX 7.1's RPM
          if version == "7.2"
            aix_72_ignoreos_hack = "--ignoreos"
          end
          on host, "rpm -ivh #{aix_72_ignoreos_hack} #{onhost_package_file}"
        else
          host.install_package(artifact_url)
        end
      end

      # Sets up the repo_configs on the host for this build
      #
      # @param [Host] host Host to install repo_configs on
      # @param [String] repoconfig_url URL to the repo_config
      #
      # @return nil
      def install_repo_configs_on(host, repoconfig_url)
        if repoconfig_url.nil?
          logger.warn("No repo_config for host '#{host}'. Skipping repo_config install")
          return
        end

        install_repo_configs_from_url( host, repoconfig_url )
      end

      # Installs a specified puppet project on all hosts. Gets build information
      #   from the provided YAML file located at the +sha_yaml_url+ parameter.
      #
      # @param [String] project_name Name of the project to install
      # @param [String] sha_yaml_url URL to the <SHA>.yaml file containing the
      #    build details
      # @param [String or Array] hosts Optional string or array of host or hosts to
      #    install on
      #
      # @note This install method only works for Puppet versions >= 5.0
      #
      # @return nil
      def install_from_build_data_url(project_name, sha_yaml_url, local_hosts = nil)
        if !link_exists?( sha_yaml_url )
          message = <<-EOF
            <SHA>.yaml URL '#{ sha_yaml_url }' does not exist.
            Please update the `sha_yaml_url` parameter to the `puppet5_install` method.
          EOF
          fail_test( message )
        end

        base_url, build_details = fetch_build_details( sha_yaml_url )

        install_targets = local_hosts.nil? ? hosts : Array(local_hosts)

        install_targets.each do |host|
          artifact_url, repoconfig_url = host_urls( host, build_details, base_url )

          # apt-get update on Ubuntu 18.04 fails when using our unsigned repos, so
          # enable this apt config here instead of having to add a cmdline flag for
          # every invocation of apt-get update:
          if host['platform'] == 'ubuntu-18.04-amd64'
            on host, "echo 'Acquire::AllowInsecureRepositories \"true\";' > /etc/apt/apt.conf.d/90insecure"
          end

          if repoconfig_url.nil?
            install_artifact_on( host, artifact_url, project_name )
          else
            install_repo_configs_on( host, repoconfig_url )
            host.install_package( project_name )
          end
          configure_type_defaults_on( host )
        end
      end

    end
  end
end

