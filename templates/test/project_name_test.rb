require File.expand_path('../test_helper', __FILE__)

class <%= const_name %>Test < Test::Unit::TestCase
  include Linecook::Test
  
  #
  # project test (build and run project as written)
  #
  
  no_cleanup
  
  def test_<%= project_name %>
    result, cmd = build_project
    assert_equal 0, $?.exitstatus, cmd
    
    result, cmd = run_project
    assert_output_equal %q{
      Hello World (from a helper)
      Hello World (from a file)
      Hello World (from a template)
    }, result, cmd
    assert_equal 0, $?.exitstatus, cmd
  end
end