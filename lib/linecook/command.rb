require 'configurable'

module Linecook
  class Command
    class << self
      def parse(argv=ARGV)
        parser = configs.to_parser(:add_defaults => false)
        yield(parser) if block_given?
        parser.sort_opts!
        parser.parse!(argv)

        new(parser.config)
      end

      def signature
        arguments = args.arguments.collect do |arg|
          arg = arg.upcase
          arg[0] == ?* ? "[#{arg[1..-1]}]" : arg
        end
        arguments.pop if arguments.last.to_s[0] == ?&
        
        "[options] #{arguments.join(' ')}"
      end

      # Returns a help string that formats the desc documentation.
      def help
        lines = desc.kind_of?(Lazydoc::Comment) ? desc.wrap(78, 2, nil) : []

        unless lines.empty?
          line = '-' * 80
          lines.unshift(line)
          lines.push(line)
        end

        lines.join("\n")
      end
    end

    extend Lazydoc::Attributes
    include Configurable

    lazy_attr :desc
    lazy_attr :args, :process
    lazy_register :process, Lazydoc::Method

    def initialize(config={})
      initialize_config(config)
    end

    def call(argv=[])
      process(*argv)
    end

    def process(*args)
      raise NotImplementedError
    end
  end

  class CommandError < RuntimeError
  end
end