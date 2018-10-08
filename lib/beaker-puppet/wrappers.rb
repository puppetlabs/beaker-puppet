module Beaker
  module DSL
    module Wrappers

      # This is hairy and because of legacy code it will take a bit more
      # work to disentangle all of the things that are being passed into
      # this catchall param.
      #
      def facter(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options['ENV'] ||= {}
        options[:cmdexe] = true
        Command.new('facter', args, options )
      end

      # This is hairy and because of legacy code it will take a bit more
      # work to disentangle all of the things that are being passed into
      # this catchall param.
      #
      def cfacter(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options['ENV'] ||= {}
        options[:cmdexe] = true
        Command.new('cfacter', args, options )
      end

      # This is hairy and because of legacy code it will take a bit more
      # work to disentangle all of the things that are being passed into
      # this catchall param.
      #
      def hiera(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options['ENV'] ||= {}
        options[:cmdexe] = true
        Command.new('hiera', args, options )
      end

      # This is hairy and because of legacy code it will take a bit more
      # work to disentangle all of the things that are being passed into
      # this catchall param.
      #
      def puppet(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options['ENV'] ||= {}
        options[:cmdexe] = true
        # we assume that an invocation with `puppet()` will have it's first argument
        # a face or sub command
        cmd = "puppet #{args.shift}"
        Command.new( cmd, args, options )
      end

      # @!visibility private
      def puppet_resource(*args)
        puppet( 'resource', *args )
      end

      # @!visibility private
      def puppet_doc(*args)
        puppet( 'doc', *args )
      end

      # @!visibility private
      def puppet_kick(*args)
        puppet( 'kick', *args )
      end

      # @!visibility private
      def puppet_cert(*args)
        puppet( 'cert', *args )
      end

      # @!visibility private
      def puppet_apply(*args)
        puppet( 'apply', *args )
      end

      # @!visibility private
      def puppet_master(*args)
        puppet( 'master', *args )
      end

      # @!visibility private
      def puppet_agent(*args)
        puppet( 'agent', *args )
      end

      # @!visibility private
      def puppet_filebucket(*args)
        puppet( 'filebucket', *args )
      end
    end
  end
end