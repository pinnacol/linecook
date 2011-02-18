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
  
  module HelperModule
    def echo(*args)
      target.puts "echo '#{args.join(' ')}'"
    end
  end
  
  def test_setup_recipe_extends_recipe_with_helpers
    setup_helpers HelperModule
    setup_recipe
    
    recipe.echo 'a', 'b', 'c'
    assert_equal "echo 'a b c'\n", recipe.result
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
  
  #
  # assert_packages test
  #
  
  no_cleanup
  
  def test_assert_packages_passes_if_default_package_in_method_dir_passes_linecook_test
    assert_project
  end
  
  def test_assert_packages_fails_if_default_package_in_method_dir_fails_linecook_test
    err = assert_raises(Test::Unit::AssertionFailedError) { assert_project }
    assert err.message.include?("<0> expected but was\n<1>")
  end
  
  def test_assert_packages_only_tests_the_specified_packages
    assert_project('abox')
    
    err = assert_raises(Test::Unit::AssertionFailedError) { assert_project('bbox') }
    assert err.message.include?("<0> expected but was\n<1>")
    
    err = assert_raises(Test::Unit::AssertionFailedError) { assert_project('abox', 'bbox') }
    assert err.message.include?("<0> expected but was\n<1>")
  end
  
  cleanup
  
  #
  # end to end tests
  #
  
  def test_a_recipe
    setup_helpers HelperModule
    setup_host 'abox'

    assert_recipe %q{
      echo 'a b c'
    } do
      echo "a", "b", "c"
    end

    assert_recipe_matches %q{
      echo 'a :...: c'
    } do
      echo "a", Time.now, "c"
    end

    assert_recipe_output %q{
      a b c
    } do
      echo "a", "b", "c"
    end

    assert_recipe_output_matches %q{
      a :...: c
    } do
      echo "a", Time.now, "c"
    end
  end
  
  def test_a_recipe_using_a_package
    setup_helpers HelperModule
    setup_host 'abox'

    setup_package(
      'letters' => ['a', 'b', 'c']
    )
    
    assert_recipe %q{
      echo 'a b c'
    } do
      echo(*attrs['letters'])
    end

    assert_recipe_matches %q{
      echo 'a :...: c'
    } do
      echo(*attrs['letters'])
    end
    
    assert_recipe_output %q{
      a b c
    } do
      echo(*attrs['letters'])
    end
    
    assert_recipe_output_matches %q{
      a :...: c
    } do
      echo(*attrs['letters'])
    end
  end

  def test_a_project
    prepare("cookbook") {}
    
    prepare('helpers/project_test_helper/echo.erb') do |io|
      io.puts "(*args)"
      io.puts "--"
      io.puts "echo <%= args.join(' ')%>"
    end

    ['abox', 'bbox'].each do |box|
      prepare("recipes/#{box}.rb") do |io|
        io.puts "$:.unshift '#{path('lib')}'"
        io.puts "helpers 'project_test_helper'"
        io.puts "echo 'run', '#{box}'"
      end

      prepare("recipes/#{box}_test.rb") do |io|
        io.puts "$:.unshift '#{path('lib')}'"
        io.puts "helpers 'project_test_helper'"
        io.puts "echo 'test', '#{box}'"
      end

      prepare("packages/#{box}.yml") {}
    end
    
    build_project
    result, exitstatus, cmd = run_project
    
    assert_equal 0, exitstatus
    
    assert_output_equal %q{
      run abox
      run bbox
      test abox
      test bbox
    }, result

    assert_alike %q{
      run a:...:
      run b:...:
      test a:...:
      test b:...:
    }, result
  end
end