module Beaker
  module DSL
    module Helpers
      # Methods that help you interact with your facter installation, facter must be installed
      # for these methods to execute correctly
      #
      module HostHelpers

        def ruby_command(host)
          if host['platform'] =~ /windows/ && !host.is_cygwin?
            "cmd /V /C \"set PATH=#{host['privatebindir']};!PATH! && ruby\""
          else
            "env PATH=\"#{host['privatebindir']}:${PATH}\" ruby"
          end
        end

        # Returns an array containing the owner, group and mode of
        # the file specified by path. The returned mode is an integer
        # value containing only the file mode, excluding the type, e.g
        # S_IFDIR 0040000
        def beaker_stat(host, path)
          ruby = ruby_command(host)
          owner = on(host, "#{ruby} -e 'require \"etc\"; puts (Etc.getpwuid(File.stat(\"#{path}\").uid).name)'").stdout.chomp
          group = on(host, "#{ruby} -e 'require \"etc\"; puts (Etc.getgrgid(File.stat(\"#{path}\").gid).name)'").stdout.chomp
          mode  = on(host, "#{ruby} -e 'puts (File.stat(\"#{path}\").mode & 0777).to_s(8)'").stdout.chomp.to_i

          [owner, group, mode]
        end

        def assert_ownership_permissions(host, location, expected_user, expected_group, expected_permissions)
          permissions = beaker_stat(host, location)
          assert_equal(expected_user, permissions[0], "Owner #{permissions[0]} does not match expected #{expected_user}")
          assert_equal(expected_group, permissions[1], "Group #{permissions[1]} does not match expected #{expected_group}")
          assert_equal(expected_permissions, permissions[2], "Permissions  #{permissions[2]} does not match expected #{expected_permissions}")
        end
      end
    end
  end
end

