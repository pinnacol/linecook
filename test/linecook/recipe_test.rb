require File.expand_path('../../test_helper', __FILE__)
require 'linecook/recipe'
require 'linecook/test'
require 'stringio'

class RecipeTest < Test::Unit::TestCase
  include Linecook::Test
  
  Package = Linecook::Package
  Recipe = Linecook::Recipe
  
  def cookbook_dir
    method_dir
  end
  
  #
  # documentation test
  #

  module Helper
    # This is compiled ERB code, prefixed by 'self.', ie:
    #
    #   "self." + ERB.new("echo '<%= args.join(' ') %>'\n").src
    #
    def echo(*args)
      self._erbout = ''; _erbout.concat "echo '"; _erbout.concat(( args.join(' ') ).to_s); _erbout.concat "'\n"
      _erbout
    end
  end

  def test_template_documentation
    package = Package.new
    recipe  = package.setup_recipe
    
    recipe.extend Helper
    recipe.instance_eval do
      echo 'a', 'b c'
      echo 'X Y'.downcase, :z
    end
    
    expected = %{
echo 'a b c'
echo 'x y z'
}
    assert_equal expected, "\n" + recipe.result

    recipe  = package.setup_recipe
    recipe.extend Helper
    recipe.instance_eval do
      echo 'outer'
      indent do
        echo 'inner'
      end
      echo 'outer'
    end

    expected = %{
echo 'outer'
  echo 'inner'
echo 'outer'
}
    assert_equal expected, "\n" + recipe.result
  end
  
  #
  # target_name test
  #
  
  def test_target_name_is_the_name_of_target_in_package
    setup_recipe 'recipe'
    assert_equal 'recipe', recipe.target_name
    assert_equal recipe.target.path, package.registry['recipe']
  end
  
  #
  # target test
  #
  
  def test_target_allows_direct_writing
    recipe.target.puts 'str'
    assert_equal "str\n", recipe.result
  end
  
  #
  # result test
  #
  
  def test_result_returns_current_template_results
    recipe.target << 'abc'
    assert_equal 'abc', recipe.result
  end
  
  def test_result_allows_further_modification
    recipe.target << 'abc'
    
    assert_equal 'abc', recipe.result
    assert_equal 'abc', recipe.result
    
    recipe.target << 'xyz'
    
    assert_equal 'abcxyz', recipe.result
  end
  
  def test_result_works_when_closed
    recipe.target << 'abc'
    recipe.close
    
    assert_equal 'abc', recipe.result
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
    prepare('files/source.txt') {|io| io << 'content'}
    
    assert_equal 'target', recipe.file_path('target', 'source.txt')
    assert_equal 'content', package.content('target')
  end
  
  #
  # recipe_path test
  #

  def test_recipe_path_evals_the_recipe_file_in_the_context_of_a_new_recipe
    prepare('recipes/source.rb') {|io| io << "target.puts 'content'"}
    assert_equal 'target', recipe.recipe_path('target', 'source')
    
    assert_equal "", package.content(recipe.target_name)
    assert_equal "content\n", package.content('target')
  end
  
  #
  # template_path test
  #

  def test_template_path_templates_and_registers_file_from_templates_dir
    prepare('templates/source.erb') do |io|
      io << "got <%= key %>"
    end
    
    assert_equal 'target', recipe.template_path('target', 'source', :key => 'value')
    assert_equal 'got value', package.content('target')
  end
  
  def test_template_path_adds_attrs_to_locals
    prepare('templates/source.erb') do |io|
      io << "got <%= attrs['key'] %><%= key %>"
    end
    
    recipe.attrs['key'] = 'val'
    recipe.template_path('target', 'source',  :key => 'ue')
    
    assert_equal 'got value', package.content('target')
  end
  
  def test_template_path_respects_attrs_manually_added_to_locals
    prepare('templates/source.erb') do |io|
      io << "got <%= attrs['key'] %>"
    end
    
    recipe.attrs['key'] = 'ignored'
    recipe.template_path('target', 'source', :attrs => {'key' => 'value'})
    
    assert_equal 'got value', package.content('target')
  end
  
  #
  # capture_path test
  #
  
  def test_capture_path_creates_file_from_recipe_block
    recipe.capture_path('target') { target << 'content'}
    assert_equal 'content', package.content('target')
  end
  
  def test_capture_path_creates_file_from_content
    path = recipe.capture_path('target', 'content')
    assert_equal 'content', package.content('target')
  end
  
  def test_nested_capture_path_produces_new_recipe_context_each_time
    recipe.capture_path('a') do 
      target << 'A'
      capture_path('b') do 
        target << 'B'
      end
    end
    
    assert_equal 'A', package.content('a')
    assert_equal 'B', package.content('b')
  end
  
  #
  # rstrip test
  #
  
  def test_rstrip_rstrips_target
    recipe.target << " a b \n "
    recipe.rstrip
    assert_equal " a b", recipe.result
  end
  
  def test_rstrip_removes_all_whitespace_up_to_start
    recipe.target << "  \n "
    recipe.rstrip
    assert_equal "", recipe.result
  end
  
  def test_rstrip_removes_lots_of_whitespace
    recipe.target << "a b"
    recipe.target << " " * 100
    recipe.rstrip
    assert_equal "a b", recipe.result
  end
end
