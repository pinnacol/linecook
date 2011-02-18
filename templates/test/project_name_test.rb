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
  
  #
  # package test
  #
  
  no_cleanup
  
  def test_<%= project_name %>
    assert_project
  end
end