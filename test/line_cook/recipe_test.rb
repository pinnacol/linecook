require File.expand_path('../../test_helper', __FILE__)
require 'line_cook/recipe'
require 'stringio'

class RecipeTest < Test::Unit::TestCase
  include LineCook::TestHelper
  Recipe = LineCook::Recipe
  
  attr_reader :recipe
  
  def setup
    super
    @recipe = Recipe.new('recipe')
  end
  
  #
  # target test
  #
  
  def test_target_allows_direct_writing
    recipe.target.puts 'str'
    assert_equal "str\n", recipe.to_s
  end
  
  #
  # target_file test
  #
  
  def test_target_file_creates_and_registers_file_with_the_specified_name_and_content
    path = recipe.target_file('name.txt', 'content')
    assert_equal 'recipe.d/0-name.txt', path
    
    source_path = recipe.registry.invert[path]
    assert_equal 'content', File.read(source_path)
  end
  
  #
  # attrs test
  #

  def test_attrs_returns_attributes_attrs
    recipe.attributes do
      default[:a] = 'A'
      default[:b] = '-'
      normal[:b] = 'B'
    end

    assert_equal({
    :a => 'A',
    :b => 'B'
    }, recipe.attrs)
  end

  #
  # attributes test
  #

  def test_attributes_evals_the_attributes_file_in_the_context_of_attributes
    prepare('attributes/example.rb') {|io| io << "default[:key] = 'value'"}
    assert_equal nil, recipe.attrs[:key]

    recipe.attributes('example')
    assert_equal 'value', recipe.attrs[:key]
  end

  def test_attributes_evals_block_in_the_context_of_attributes
    assert_equal nil, recipe.attrs[:key]

    recipe.attributes { default[:key] = 'value' }
    assert_equal 'value', recipe.attrs[:key]
  end

  #
  # helpers test
  #

  module HelpersModule
    def help; end
  end

  def test_helpers_looks_up_module_and_extends_self
    assert_equal false, recipe.respond_to?(:help)
    recipe.helpers "recipe_test/helpers_module"
    assert_equal true, recipe.respond_to?(:help)
  end

  #
  # file_path test
  #

  def test_file_path_registers_file_from_files_dir
    prepare('files/example.txt') {|io| io << 'content'}

    path = recipe.file_path('example.txt')
    assert_equal 'recipe.d/0-example.txt', path

    source_path = recipe.registry.invert[path]
    assert_equal 'content', File.read(source_path)
  end

  #
  # recipe_path test
  #

  def test_recipe_path_evals_the_recipe_file_in_the_context_of_a_new_recipe
    prepare('recipes/example.rb') {|io| io << "target.puts 'content'"}
    assert_equal 'example', recipe.recipe_path('example')

    recipe.close

    source_path = recipe.registry.invert['recipe']
    assert_equal "", File.read(source_path)

    source_path = recipe.registry.invert['example']
    assert_equal "content\n", File.read(source_path)
  end

  def test_recipe_path_evals_block_in_the_context_of_a_new_recipe
    path = recipe.recipe_path('example') { target.puts "content" }
    assert_equal 'example', path

    recipe.close

    source_path = recipe.registry.invert['recipe']
    assert_equal "", File.read(source_path)

    source_path = recipe.registry.invert['example']
    assert_equal "content\n", File.read(source_path)
  end
  
  #
  # script_path test
  #
  
  def test_script_path_concats_script_file_if_it_exists
    prepare('scripts/example.sh') {|io| io << "content" }
    
    path = recipe.script_path('example.sh')
    assert_equal 'recipe.d/0-example.sh', path
    
    source_path = recipe.registry.invert[path]
    assert_equal 'content', File.read(source_path)
  end
  
  def test_script_path_reassigns_script_to_tempfile_for_duration_of_block
    path = recipe.script_path('example.sh') { target << 'content'}
    assert_equal 'recipe.d/0-example.sh', path
    
    source_path = recipe.registry.invert[path]
    assert_equal 'content', File.read(source_path)
  end

  #
  # template_path test
  #

  def test_template_path_templates_and_registers_file_from_templates_dir
    prepare('templates/example.txt.erb') do |io|
      io << "got <%= key %>"
    end

    path = recipe.template_path('example.txt', :key => 'value')
    assert_equal 'recipe.d/0-example.txt', path

    source_path = recipe.registry.invert[path]
    assert_equal 'got value', File.read(source_path)
  end
  
  #
  # rstrip test
  #
  
  def test_rstrip_rstrips_target
    recipe.target << " a b \n "
    recipe.rstrip
    assert_equal " a b", recipe.to_s
  end
  
  def test_rstrip_removes_all_whitespace_up_to_start
    recipe.target << "  \n "
    recipe.rstrip
    assert_equal "", recipe.to_s
  end
  
  def test_rstrip_removes_lots_of_whitespace
    recipe.target << "a b"
    recipe.target << " " * 100
    recipe.rstrip
    assert_equal "a b", recipe.to_s
  end
  
  #
  # current/next count test
  #
  
  def test_next_count_increments_and_returns_current_count
    assert_equal 0, recipe.current_count
    assert_equal 1, recipe.next_count
    assert_equal 1, recipe.current_count
  end
end
