require File.expand_path('../../test_helper', __FILE__)
require 'linecook/recipe'
require 'linecook/test'
require 'stringio'

class RecipeTest < Test::Unit::TestCase
  include Linecook::Test
  Recipe = Linecook::Recipe
  
  attr_accessor :manifest
  
  def setup
    super
    use_method_dir_manifest
  end
  
  #
  # source_path test
  #
  
  def test_source_path_returns_corresponding_path_in_manifest
    manifest['relative/path'] = 'source/path'
    assert_equal 'source/path', recipe.source_path('relative/path')
  end
  
  def test_source_path_joins_path_segments
    manifest['relative/path'] = 'source/path'
    assert_equal 'source/path', recipe.source_path('relative', 'path')
  end
  
  def test_source_path_raises_error_for_path_unregistered_in_manifest
    err = assert_raises(RuntimeError) { recipe.source_path('unknown/path') }
    assert_equal 'no such file in manifest: "unknown/path"', err.message
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
    
    registry = recipe.close
    
    source_path = registry[path]
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
    assert_equal 'recipe.d/example.txt', path

    source_path = recipe.registry.invert[path]
    assert_equal 'content', File.read(source_path)
  end
  
  #
  # capture_path test
  #
  
  def test_capture_path_creates_file_from_block
    path = recipe.capture_path('example.sh') { target << 'content'}
    assert_equal 'recipe.d/example.sh', path
    
    registry = recipe.close
    
    source_path = registry[path]
    assert_equal 'content', File.read(source_path)
  end
  
  #
  # recipe_path test
  #

  def test_recipe_path_evals_the_recipe_file_in_the_context_of_a_new_recipe
    file('recipes/example.rb') {|io| io << "target.puts 'content'"}
    assert_equal 'example', recipe.recipe_path('example')

    registry = recipe.close
    
    source_path = registry['recipe']
    assert_equal "", File.read(source_path)

    source_path = registry['example']
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
    assert_equal 'recipe.d/example.txt', path
    
    registry = recipe.close
    
    source_path = registry[path]
    assert_equal 'got value', File.read(source_path)
  end
end
