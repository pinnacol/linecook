require 'linecook/commands/command_error'
require 'configurable'

module Linecook
  module Commands
    class Command
      class << self
        def registry
          @registry ||= {}
        end
        
        def inherited(base)
          super
          registry[base.to_s.split('::').last.downcase] = base
        end
      end
      
      extend Lazydoc::Attributes
      include Configurable
      
      lazy_attr :desc
      
      def initialize(config)
        initialize_config(config)
      end
      
      def log(action, msg)
        puts("      %s  %s" % [action, msg])
      end
    end
  end
end