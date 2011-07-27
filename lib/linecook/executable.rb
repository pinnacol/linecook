require 'linecook/command_set'
require 'linecook/commands/compile'

module Linecook
  class Executable < Linecook::CommandSet
    class << self
      def commands
        {
          'compile' => Linecook::Commands::Compile,
          'compile_helper' => Linecook::Commands::CompileHelper
        }
      end
    end
  end
end
