require File.expand_path('../../../test_helper', __FILE__)
require 'linecook/shell/utils'
require 'linecook/test'

class ShellUtilsTest < Test::Unit::TestCase
  include Linecook::Test
  
  def recipe
    use_method_dir_manifest
    super.extend Linecook::Shell::Utils
  end
  
  #
  # recipe test
  #
  
  def test_recipe_evals_recipe_into_recipe_file
    file('recipes/name.rb') {|io| io << "target << 'content'" }
    
    recipe.instance_eval { recipe('name') }
    assert_content 'content', 'name'
  end
end