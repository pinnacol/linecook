require 'linecook/command_set'
require 'linecook/commands/build'
require 'linecook/commands/start'
require 'linecook/commands/stop'
require 'linecook/commands/state'
require 'linecook/commands/snapshot'
require 'linecook/commands/ssh'
require 'linecook/commands/run'

module Linecook
  class Executable < Linecook::CommandSet
    class << self
      def commands
        {
          'build'          => Linecook::Commands::Build,
          'compile'        => Linecook::Commands::Compile,
          'compile-helper' => Linecook::Commands::CompileHelper,
          'start'          => Linecook::Commands::Start,
          'stop'           => Linecook::Commands::Stop,
          'state'          => Linecook::Commands::State,
          'snapshot'       => Linecook::Commands::Snapshot,
          'ssh'            => Linecook::Commands::Ssh,
          'run'            => Linecook::Commands::Run
        }
      end
    end
  end
end
