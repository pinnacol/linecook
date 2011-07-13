require 'configurable'

module Linecook
  class Command
    class << self
      def name
        @name ||= to_s.split('::').last.downcase
      end

      def parse(argv=ARGV, &block)
        parse!(argv.dup, &block)
      end

      def parse!(argv=ARGV, &block)
        parser = configs.to_parser(:add_defaults => false, &block)
        parser.parse!(argv)
        
        [parser.config, argv]
      end

      def call(argv=[])
        new(config).call(argv)
      end

      # Returns a help string that formats the desc documentation.
      def help
        lines = desc.kind_of?(Lazydoc::Comment) ? desc.wrap(77, 2, nil) : []
        lines.collect! {|line| "  #{line}"}

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
    
    class CommandError < RuntimeError
    end
  end
end