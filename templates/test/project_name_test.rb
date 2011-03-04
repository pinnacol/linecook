require File.expand_path('../test_helper', __FILE__)

class <%= const_name %>Test < Test::Unit::TestCase
  include Linecook::Test
  
  #
  # create_dir test
  #
  
  def test_create_dir_creates_a_non_existant_dir
    # assert_recipe builds the recipe in the block and checks that the
    # result is as specified (note the result is outdented by default)
    
    assert_recipe(%{
      if ! [ -d dir ]
      then
        echo "Create dir: dir"
        mkdir -p dir
      fi
      
    }){
      helpers '<%= project_name %>'
      create_dir 'dir'
    }
    
    # now run all recipes you've created in the test
    assert_output_equal %{
      Create dir: dir
    }, *run_package
  end
  
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