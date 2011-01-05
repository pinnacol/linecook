require 'linecook/commands/command_error'
require 'configurable'

module Linecook
  module Commands
    class Command
      extend Lazydoc::Attributes
      include Configurable
      
      lazy_attr :desc
      lazy_attr :name
      
      def initialize(config)
        initialize_config(config)
      end
      
      def log(action, msg)
        puts("      %s  %s" % [action, msg])
      end
    end
  end
end