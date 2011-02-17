require File.expand_path('../../../test_helper', __FILE__) 
require 'linecook/commands'
require 'linecook/test'

class CommandTest < Test::Unit::TestCase
  include Linecook::Test
  
  Command = Linecook::Commands::Command
  CommandError = Linecook::Commands::CommandError
  
  attr_accessor :cmd
  
  def setup
    super
    @cmd = Command.new
  end
  
  #
  # sh! test
  #
  
  def test_sh_bang_raises_no_error_for_zero_exit
    cmd.quiet = true
    assert_nothing_raised { cmd.sh!('true') }
  end
  
  def test_sh_bang_raises_error_with_shell_exit_status_for_non_zero_exit
    cmd.quiet = true
    
    script = prepare('script') {|io| io << "exit 8"}
    
    err = assert_raises(CommandError) { cmd.sh!("sh '#{script}'") }
    assert_equal 8, err.exitstatus
  end
end