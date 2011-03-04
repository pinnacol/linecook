require File.expand_path('../../test_helper', __FILE__)
require 'linecook/test'

class TestTest < Test::Unit::TestCase
  include Linecook::Test
  
  #
  # setup_cookbook test
  #
  
  def test_setup_cookbook_initializes_project_dir_to_method_dir
    cookbook = setup_cookbook
    assert_equal method_dir, cookbook.project_dir
  end
  
  def test_setup_cookbook_uses_config_if_specified
    cookbook = setup_cookbook('paths' => 'a:b:c', 'gems' => 'x:y:z')
    assert_equal ['a', 'b', 'c'], cookbook.paths
    assert_equal ['x', 'y', 'z'], cookbook.gems
  end
  
  def test_setup_cookbook_uses_cookbook_file_if_specified
    cookbook_file = prepare('file') do |io|
      YAML.dump({'paths' => 'a:b:c', 'gems' => 'x:y:z'}, io)
    end
    
    cookbook = setup_cookbook(cookbook_file)
    assert_equal ['a', 'b', 'c'], cookbook.paths
    assert_equal ['x', 'y', 'z'], cookbook.gems
  end
  
  def test_setup_cookbook_detects_and_uses_existing_cookbook_file
    prepare('cookbook') {|io| YAML.dump({'paths' => 'a:b:c', 'gems' => 'x:y:z'}, io) }
    
    cookbook = setup_cookbook
    assert_equal ['a', 'b', 'c'], cookbook.paths
    assert_equal ['x', 'y', 'z'], cookbook.gems
  end
  
  def test_setup_cookbook_sets_cookbook
    a = prepare('a/files/example.txt') {|io| }
    b = prepare('b/files/example.txt') {|io| }
    
    setup_cookbook(nil, path('a'))
    assert_equal a, cookbook.manifest['files']['example.txt']
    
    setup_cookbook(nil, path('b'))
    assert_equal b, cookbook.manifest['files']['example.txt']
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
    
    setup_cookbook({}, method_dir)
    setup_package
    
    assert_equal true, package.resource?('files', 'example.txt')
  end
  
  #
  # use_helpers test
  #
  
  def test_use_helpers_sets_helpers
    use_helpers :a, :b
    assert_equal [:a, :b], helpers
    
    use_helpers :x, :y
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
    use_helpers HelperModule
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
  # test scenarios
  #
  
  def test_a_recipe
    use_helpers HelperModule
    
    setup_package(
      'letters' => ['a', 'b', 'c']
    )
    
    assert_recipe %q{
      echo 'a b c'
    } do
      echo(*attrs['letters'])
    end
  end
  
  def test_a_package
    use_helpers HelperModule
    use_host 'abox'
    
    setup_recipe do
      target.puts "echo b0nk"
      target.puts "exit 8"
    end
    
    stdout, msg = run_package
    assert_output_equal %{
      b0nk
    }, stdout, msg
    
    assert_alike %{
      % :...:
      [8] test/linecook/test_test/test_a_package/recipe 
    }, msg
    
    assert_equal 1, $?.exitstatus, msg
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

    stdout, msg = build_project
    assert_equal 0, $?.exitstatus, msg
    
    stdout, msg = run_project
    assert_output_equal %q{
      run abox
      run bbox
      test abox
      test bbox
    }, stdout, msg
    assert_equal 0, $?.exitstatus, msg
  end
  
  cleanup_paths 'log'
  
  def test_a_static_project
    stdout, msg = build_project
    assert_equal 0, $?.exitstatus, msg
    
    stdout, msg = run_project
    assert_output_equal %q{
      run
      test
    }, stdout, msg
    assert_equal 1, $?.exitstatus, msg
  end
  
  cleanup
end
