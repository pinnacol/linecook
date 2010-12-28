require File.expand_path('../../test_helper', __FILE__)
require 'linecook/recipe'
require 'linecook/test'
require 'stringio'

class RecipeTest < Test::Unit::TestCase
  include Linecook::Test
  Recipe = Linecook::Recipe
  
  attr_reader :recipe
  
  def setup
    super
    @recipe = Recipe.new 'recipe'
  end
  
  #
  # initialize test
  #
  
  def test_default_manifest_returns_full_path_for_existing_files
    path = file('existing/file')
    assert_equal path, recipe.manifest['existing/file']
  end

  def test_default_manifest_returns_nil_for_missing_files
    assert_equal false, File.exists?(path('missing/file'))
    assert_equal nil, recipe.manifest['missing/file']
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
    assert_equal 'recipe.d/0-name.txt', path
    
    recipe.close
    
    source_path = recipe.registry.invert[path]
    assert_equal 'content', File.read(source_path)
  end

  #
  # attributes test
  #

  def test_attributes_evals_the_attributes_file_in_the_context_of_attributes
    file('attributes/example.rb') {|io| io << "attrs[:key] = 'value'"}
    assert_equal nil, recipe.attrs[:key]

    recipe.attributes('example')
    assert_equal 'value', recipe.attrs[:key]
  end
  
  #
  # helpers test
  #
  
  def test_helpers_requires_helper_and_extends_self_with_helper_module
    file('lib/recipe_test/require_helper.rb') {|io| io << %q{
      class RecipeTest
        module RequireHelper
          def help; end
        end
      end
    }}
    
    lib_path = path('lib')
    begin
      $:.unshift lib_path
      
      assert_equal false, recipe.respond_to?(:help)
      recipe.helpers "recipe_test/require_helper"
      assert_equal true, recipe.respond_to?(:help)
      
    ensure
      $:.delete lib_path
    end
  end

  #
  # file_path test
  #

  def file_path_registers_file_from_files_dir
    file('files/example.txt') {|io| io << 'content'}

    path = recipe.file_path('example.txt')
    assert_equal 'recipe.d/0-example.txt', path

    source_path = recipe.registry.invert[path]
    assert_equal 'content', File.read(source_path)
  end
  
  #
  # capture_path test
  #
  
  def test_capture_path_creates_file_from_block
    path = recipe.capture_path('example.sh') { target << 'content'}
    assert_equal 'recipe.d/0-example.sh', path
    
    recipe.close
    
    source_path = recipe.registry.invert[path]
    assert_equal 'content', File.read(source_path)
  end
  
  #
  # recipe_path test
  #

  def test_recipe_path_evals_the_recipe_file_in_the_context_of_a_new_recipe
    file('recipes/example.rb') {|io| io << "target.puts 'content'"}
    assert_equal 'example', recipe.recipe_path('example')

    recipe.close

    source_path = recipe.registry.invert['recipe']
    assert_equal "", File.read(source_path)

    source_path = recipe.registry.invert['example']
    assert_equal "content\n", File.read(source_path)
  end
  
  #
  # template_path test
  #

  def test_template_path_templates_and_registers_file_from_templates_dir
    file('templates/example.txt.erb') do |io|
      io << "got <%= key %>"
    end

    path = recipe.template_path('example.txt', :key => 'value')
    assert_equal 'recipe.d/0-example.txt', path
    
    recipe.close
    
    source_path = recipe.registry.invert[path]
    assert_equal 'got value', File.read(source_path)
  end
end
