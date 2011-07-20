require 'linecook/command'

module Linecook
  class CommandSet < Command
    class << self
      def commands
        # assume/require word names
        @commands ||= {}
      end

      def parse(argv=ARGV)
        command = super(argv) do |options|
          options.option_break = /\A(?:--\z|[^-])/
          options.preserve_option_break = true
          yield(options) if block_given?
        end

        # The parser is configured to preserve the break, which is desired
        # when it's a command, but you want to get rid of standard breaks.
        if argv[0] == '--'
          argv.shift
        end

        command
      end
      
      def run(argv=ARGV, &block)
        command = parse(argv) do |options|
          if block_given?
            yield([], self, options)
          end
        end
        
        command.call(argv, &block)
      end

      def command_list
        commands.keys.sort.collect do |name|
          [name, commands[name]]
        end
      end
    end

    def call(argv=[])
      if argv.empty?
        raise CommandError, "no command specified"
      end

      command_name  = argv.shift
      command_class = self.class.commands[command_name]

      unless command_class
        raise CommandError, "unknown command: #{command_name.inspect}"
      end

      # Parse options for the command, but yield with the necessary debugging
      # information - note that command_class is always the latest one to be
      # parsed so start with the command name as the callpath.
      command = command_class.parse(argv) do |options|
        if block_given?
          yield([command_name], command_class, options)
        end
      end

      if command.kind_of?(CommandSet)
        # The block causes nested CommandSets to roll back out to the main
        # context with the callpath and latest command_class. Literally it
        # wraps the block defined above.  Non-CommandSet commands will have
        # nil, not a block passed to call - a NOP.
        command.call(argv) do |callpath, cmdclass, options|
          if block_given?
            callpath.unshift(command_name)
            yield(callpath, cmdclass, options)
          end
        end
      else
        process(command, *argv)
      end
    end

    def process(command, *args)
      command.call(args)
    end
  end
end