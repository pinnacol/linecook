require 'linecook/command_set'
require 'linecook/commands/compile'

module Linecook
  class Executable < Linecook::CommandSet
    class << self
      def commands
        {'compile' => Linecook::Commands::Compile}
      end
    end
  end
end
