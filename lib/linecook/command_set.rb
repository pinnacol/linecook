require 'linecook/command'

module Linecook
  class CommandSet < Command
    class << self
      def commands
        # assume/require word names
        @commands ||= {}
      end

      def parse!(argv=ARGV)
        super do |options|
          options.option_break = /\A(?:--\z|[^-])/
          yield(options) if block_given?
        end
      end

      def command_list
        commands.keys.sort.collect do |name|
          [name, commands[name]]
        end
      end
    end

    def process(command_name, *args)
      command_class = self.class.commands[command_name]

      unless command_class
        raise CommandError, "unknown command: #{command_name.inspect}"
      end

      block = lambda do |(path, cmd, opts)|
        if block_given?
          path, cmd, opts = [], command_class, path if opts.nil?
          path.unshift(command_name)

          yield(path, cmd, opts)
        end
      end
      command = command_class.parse!(args, &block) 

      unless command.kind_of?(CommandSet)
        block = nil 
      end

      command.call(args, &block)
    end
  end
end