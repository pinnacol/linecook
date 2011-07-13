require 'linecook/command_set'
require 'linecook/commands/compile'

module Linecook
  Executable = CommandSet.new('linecook',
    'compile' => Linecook::Commands::Compile
  )
end
