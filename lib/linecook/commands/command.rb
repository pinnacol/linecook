require 'linecook/commands/command_error'
require 'configurable'

module Linecook
  module Commands
    class Command
      class << self
        def registry
          REGISTRY
        end
        
        def inherited(base)
          super
          registry[base.to_s.split('::').last.downcase] = base
        end
      end
      
      REGISTRY = {}
      
      extend Lazydoc::Attributes
      include Configurable
      
      lazy_attr :desc
      lazy_attr :args, :process
      lazy_register :process, Lazydoc::Arguments
      
      def initialize(config)
        initialize_config(config)
      end
      
      def log(action, msg)
        puts("      %s  %s" % [action, msg])
      end
      
      def sh(cmd)
        system cmd
      end
      
      def call(argv)
        process(*argv)
      end
      
      def process(*args)
        raise NotImplementedError
      end
    end
  end
end