require File.expand_path('../test_helper', __FILE__)

class <%= const_name %>Test < Test::Unit::TestCase
  include Linecook::Test
  
  #
  # echo test
  #
  
  def test_echo_creates_a_command_to_echo_the_args
    # assert_recipe builds the recipe in the block and checks that the
    # result is as specified (note the result is outdented by default)
    
    assert_recipe(%{
      echo 'a b c'
    }){
      helpers '<%= project_name %>'
      echo 'a', 'b c'
    }
  end
  
  def test_echo_actually_echos_args_to_command_line
    # build_package builds the recipe into a package.  check_package copies
    # the package to each vm named in config/ssh and runs the commands on
    # the vm as specified; if the exit status is 0 for each command, and
    # the stdout is as written, then the check passes.
    
    build_package { 
      helpers '<%= project_name %>'
      echo 'a', 'b c'
    }
    
    check_package %{
      % sh package/recipe | tee output.txt
      a b c
      % cat output.txt
      a b c
    }
  end
end