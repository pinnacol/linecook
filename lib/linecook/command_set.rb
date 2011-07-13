require 'linecook/command'

module Linecook
  class CommandSet
    include Configurable

    attr_reader :name
    attr_reader :commands

    def initialize(name, commands={})
      @name = name
      @commands = commands
      initialize_config
    end

    def usage(command=nil)
      base = "usage: #{name} [options]"
      command ? "#{base} #{command.name} #{command.args}" : "#{base} -- COMMAND"
    end

    def command_list
      commands.keys.sort.collect do |name|
        [name, commands[name]]
      end
    end

    def call(argv)
      command_name = argv.shift
      command = commands[command_name]

      unless command
        raise Command::CommandError, "unknown command: #{command_name.inspect}"
      end

      config, args = command.parse!(argv) do |parser|
        yield(command, parser)
      end

      command.call(config, args)
    end

    def parse(argv=ARGV, &block)
      parse!(argv.dup, &block)
    end

    def parse!(argv=ARGV, &block)
      if command = argv.find {|arg| arg[0] != ?- }
        argv.insert(argv.index(command), '--')
      end

      config.parse!(&block)
    end
  end
end