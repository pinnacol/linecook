require 'linecook/command_set'
require 'linecook/commands/compile'
require 'linecook/commands/start'
require 'linecook/commands/stop'
require 'linecook/commands/state'
require 'linecook/commands/snapshot'

module Linecook
  class Executable < Linecook::CommandSet
    class << self
      def commands
        {
          'compile'        => Linecook::Commands::Compile,
          'compile_helper' => Linecook::Commands::CompileHelper,
          'start'          => Linecook::Commands::Start,
          'stop'           => Linecook::Commands::Stop,
          'state'          => Linecook::Commands::State,
          'snapshot'       => Linecook::Commands::Snapshot
        }
      end
    end
  end
end
