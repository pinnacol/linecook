require File.expand_path('../../test_helper', __FILE__)
require 'linecook/shell'
require 'linecook/test'

# Can't name this one ShellTest due to collision with the shell_test gem.
class ShellHelpersTest < Test::Unit::TestCase
  include Linecook::Test

  def setup
    super
    use_helpers Linecook::Shell
  end

  module HelperModule
  end

  #
  # extended test
  #

  def test_extend_shell_extends_with_os_as_specifed_in_attrs
    setup_package('linecook' => {'os' => HelperModule})

    recipe = setup_recipe
    recipe.extend Linecook::Shell
    assert_equal true, setup_recipe.kind_of?(HelperModule)
  end

  def test_extend_shell_looks_up_os_helper
    setup_package('linecook' => {'os' => 'shell_helpers_test/helper_module'})

    recipe = setup_recipe
    recipe.extend Linecook::Shell
    assert_equal true, setup_recipe.kind_of?(HelperModule)
  end

  def test_extend_shell_extends_with_shell_as_specifed_in_attrs
    setup_package('linecook' => {'shell' => HelperModule})

    recipe = setup_recipe
    recipe.extend Linecook::Shell
    assert_equal true, setup_recipe.kind_of?(HelperModule)
  end

  def test_extend_shell_looks_up_shell_helper
    setup_package('linecook' => {'shell' => 'shell_helpers_test/helper_module'})

    recipe = setup_recipe
    recipe.extend Linecook::Shell
    assert_equal true, setup_recipe.kind_of?(HelperModule)
  end
end