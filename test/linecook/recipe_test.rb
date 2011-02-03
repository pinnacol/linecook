require File.expand_path('../../test_helper', __FILE__)
require 'linecook/recipe'
require 'linecook/test'
require 'stringio'

class RecipeTest < Test::Unit::TestCase
  include Linecook::Test
  Recipe = Linecook::Recipe
  
  def cookbook_dir
    method_dir
  end
  
  #
  # target_name test
  #
  
  def test_target_name_is_the_name_of_target_in_package
    setup_recipe 'recipe'
    
    assert_equal 'recipe', package.target_name(recipe.target.path)
    assert_equal 'recipe', recipe.target_name
  end
  
  #
  # target test
  #
  
  def test_target_allows_direct_writing
    recipe.target.puts 'str'
    assert_equal "str\n", recipe.result
  end
  
  #
  # target_file test
  #
  
  def test_target_file_creates_and_registers_file_with_the_specified_name_and_content
    path = recipe.target_file('name.txt', 'content')
    
    assert_equal 'recipe.d/name.txt', path
    assert_equal 'content', package.content(path)
  end
  
  def test_target_file_can_accept_content_via_a_block
    path = recipe.target_file('name.txt') {|io| io << 'content'}
    
    assert_equal 'recipe.d/name.txt', path
    assert_equal 'content', package.content(path)
  end

  #
  # attributes test
  #

  def test_attributes_evals_the_attributes_file_in_the_context_of_attributes
    prepare('attributes/example.rb') {|io| io << "attrs[:key] = 'value'"}
    assert_equal nil, recipe.attrs[:key]
    
    recipe.attributes('example')
    assert_equal 'value', recipe.attrs[:key]
  end
  
  def test_attributes_evals_a_block_for_attrs
    assert_equal nil, recipe.attrs[:key]
    
    recipe.attributes do
      attrs[:key] = 'value'
    end
    
    assert_equal 'value', recipe.attrs[:key]
  end
  
  #
  # attrs test
  #
  
  def test_attrs_merges_attrs_and_env_where_env_wins
    package.env[:a] = 'A'
    
    recipe.attributes do
      attrs[:a]     = '-'
      attrs[:b]     = 'B'
    end

    assert_equal 'A', recipe.attrs[:a]
    assert_equal 'B', recipe.attrs[:b]
  end
  
  def test_attrs_are_additive_and_still_ensure_env_wins
    package.env[:a] = 'A'
    
    recipe.attributes do
      attrs[:a]     = '-'
      attrs[:b]     = '-'
      attrs[:c]     = 'C'
    end
    
    recipe.attributes do
      attrs[:b]     = 'B'
    end
    
    assert_equal 'A', recipe.attrs[:a]
    assert_equal 'B', recipe.attrs[:b]
    assert_equal 'C', recipe.attrs[:c]
  end
  
  def test_attrs_performs_deep_merge
    recipe.attributes do
      attrs[:a] = 'A'
      attrs[:b] = '-'
      attrs[:one][:a] = 'a'
      attrs[:one][:b] = '-'
    end
    
    package.env[:b]   = 'B'
    package.env[:one] = {:b => 'b'}
    
    assert_equal 'A', recipe.attrs[:a]
    assert_equal 'B', recipe.attrs[:b]
    assert_equal({:a => 'a', :b => 'b'}, recipe.attrs[:one])
  end
  
  def test_attrs_does_not_auto_nest
    recipe.attributes { attrs[:b] }
    
    assert_equal nil, recipe.attrs[:a]
    assert_equal nil, recipe.attrs[:b][:c]
  end
  
  #
  # helpers test
  #
  
  def test_helpers_requires_helper_and_extends_self_with_helper_module
    prepare('lib/recipe_test/require_helper.rb') {|io| io << %q{
      class RecipeTest
        module RequireHelper
          def help; end
        end
      end
    }}
    
    lib_dir = path('lib')
    begin
      $:.unshift lib_dir
      
      assert_equal false, recipe.respond_to?(:help)
      recipe.helpers "recipe_test/require_helper"
      assert_equal true, recipe.respond_to?(:help)
    ensure
      $:.delete lib_dir
    end
  end

  #
  # file_path test
  #

  def file_path_registers_file_from_files_dir
    prepare('files/example.txt') {|io| io << 'content'}
    
    path = recipe.file_path('example.txt')
    assert_equal 'recipe.d/example.txt', path
    assert_equal 'content', package.content(path)
  end
  
  #
  # capture_path test
  #
  
  def test_capture_path_creates_file_from_recipe_block
    path = recipe.capture_path('example.sh') { target << 'content'}
    
    assert_equal 'recipe.d/example.sh', path
    assert_equal 'content', package.content(path)
  end
  
  def test_nested_capture_path_produces_new_recipe_context_each_time
    recipe.capture_path('a') do 
      target << 'A'
      capture_path('b') do 
        target << 'B'
      end
    end
    
    assert_equal 'A', package.content('recipe.d/a')
    assert_equal 'B', package.content('recipe.d/b')
  end
  
  #
  # recipe_path test
  #

  def test_recipe_path_evals_the_recipe_file_in_the_context_of_a_new_recipe
    prepare('recipes/example.rb') {|io| io << "target.puts 'content'"}
    assert_equal 'example', recipe.recipe_path('example')
    
    assert_equal "", package.content('recipe')
    assert_equal "content\n", package.content('example')
  end
  
  #
  # template_path test
  #

  def test_template_path_templates_and_registers_file_from_templates_dir
    prepare('templates/example.txt.erb') do |io|
      io << "got <%= key %>"
    end
    
    path = recipe.template_path('example.txt', :key => 'value')
    
    assert_equal 'recipe.d/example.txt', path
    assert_equal 'got value', package.content(path)
  end
  
  def test_template_path_adds_attrs_to_locals
    prepare('templates/example.txt.erb') do |io|
      io << "got <%= attrs['key'] %><%= key %>"
    end
    
    recipe.attrs['key'] = 'val'
    path = recipe.template_path('example.txt', :key => 'ue')
    
    assert_equal 'recipe.d/example.txt', path
    assert_equal 'got value', package.content(path)
  end
  
  def test_template_path_respects_attrs_manually_added_to_locals
    prepare('templates/example.txt.erb') do |io|
      io << "got <%= attrs['key'] %><%= key %>"
    end
    
    recipe.attrs['key'] = 'ignored'
    path = recipe.template_path('example.txt', :key => 'ue', :attrs => {'key' => 'val'})
    
    assert_equal 'recipe.d/example.txt', path
    assert_equal 'got value', package.content(path)
  end
end
