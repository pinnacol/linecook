require File.expand_path('../test_helper', __FILE__)

class <%= const_name %>Test < Test::Unit::TestCase
  include Linecook::Test
  
  #
  # package test
  #
  
  no_cleanup
  
  def test_<%= project_name %>
    result, cmd = build_project
    assert_equal 0, $?.exitstatus, cmd
    
    result, cmd = run_project
    assert_equal 0, $?.exitstatus, cmd
  end
end