require File.expand_path('../../test_helper', __FILE__)
require 'linecook/test'

class LinecookTestTest < Test::Unit::TestCase
  include Linecook::Test
  
  #
  # setup_cookbook test
  #
  
  def test_setup_cookbook_initializes_cookbook_to_dir
    path = prepare('files/example.txt') {|io| }
    cookbook = setup_cookbook method_dir
    
    assert_equal path, cookbook.manifest['files']['example.txt']
  end
  
  def test_setup_cookbook_sets_cookbook
    a = prepare('a/files/example.txt') {|io| }
    b = prepare('b/files/example.txt') {|io| }
    
    setup_cookbook path('a')
    assert_equal a, cookbook.manifest['files']['example.txt']
    
    setup_cookbook path('b')
    assert_equal b, cookbook.manifest['files']['example.txt']
  end
  
  def test_setup_cookbook_initializes_to_method_dir_if_it_exists
    prepare('files/example.txt') {|io| }
    assert_equal method_dir, setup_cookbook.project_dir
  end
  
  def test_setup_cookbook_initializes_to_user_dir_if_method_dir_does_not_exist
    assert_equal user_dir, setup_cookbook.project_dir
  end
  
  #
  # setup_package test
  #
  
  def test_setup_package_initializes_package_with_env
    package = setup_package 'key' => 'value'
    assert_equal 'value', package.env['key']
  end
  
  def test_setup_package_sets_package
    setup_package 'key' => 'a'
    assert_equal 'a', package.env['key']
    
    setup_package 'key' => 'b'
    assert_equal 'b', package.env['key']
  end
  
  def test_setup_package_uses_cookbook_as_currently_set
    prepare('files/example.txt') {|io| }
    
    setup_cookbook method_dir
    setup_package
    
    assert_equal true, package.resource?('files', 'example.txt')
  end
  
  #
  # setup_helpers test
  #
  
  def test_setup_helpers_sets_helpers
    setup_helpers :a, :b
    assert_equal [:a, :b], helpers
    
    setup_helpers :x, :y
    assert_equal [:x, :y], helpers
  end
  
  #
  # setup_recipe test
  #
  
  def test_setup_recipe_initializes_a_new_recipe_with_the_target_name
    recipe = setup_recipe('a')
    assert_equal 'a', recipe.target_name
  end
  
  def test_setup_recipe_sets_recipe
    setup_recipe
    recipe.target << 'a'
    assert_equal 'a', recipe.result
    
    setup_recipe
    recipe.target << 'b'
    assert_equal 'b', recipe.result
  end
  
  def test_setup_recipe_resets_package
    setup_recipe('recipe')
    recipe.target << 'a'
    recipe.close
    assert_equal 'a', package.content('recipe')
    
    setup_recipe('recipe')
    recipe.target << 'b'
    recipe.close
    assert_equal 'b', package.content('recipe')
  end
  
  module HelperModule
    def echo(*args)
      target.puts "echo #{args.join(' ')}"
    end
  end
  
  def test_setup_recipe_extends_recipe_with_helpers
    setup_helpers HelperModule
    setup_recipe
    
    recipe.echo 'a', 'b', 'c'
    assert_equal "echo a b c\n", recipe.result
  end
  
  #
  # assert_recipe test
  #
  
  def test_assert_recipe_passes_if_expected_and_actual_content_are_the_same
    assert_recipe %q{
      content
    } do
      target.puts "content"
    end
  end
  
  def test_assert_recipe_passes_if_expected_and_actual_content_differ
    assert_raises(Test::Unit::AssertionFailedError) do
      assert_recipe %q{
        expected
      } do
        target.puts "actual"
      end
    end
  end
  
  def test_assert_recipe_makes_new_recipe_for_each_call
    assert_recipe('a') { target << 'a'}
    assert_recipe('b') { target << 'b'}
  end
  
  def test_assert_recipe_returns_recipe
    recipe = assert_recipe('a') { target << 'a'}
    assert_equal 'a', recipe.result
  end
  
  def test_assert_recipe_may_specify_recipe_to_check
    recipe = assert_recipe('a') { target << 'a'}
    assert_recipe('a', recipe)
  end
  
  def test_assert_recipe_evaluates_block_for_recipe_if_specified
    recipe = assert_recipe('a') { target << 'a'}
    assert_recipe('ab', recipe) { target << 'b'}
  end
  
  def test_assert_recipe_uses_current_package_if_set
    setup_package('key' => 'value')
    assert_recipe('value') { target << attrs['key'] }
  end
end