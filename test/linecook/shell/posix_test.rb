require File.expand_path('../../../test_helper', __FILE__)
require 'linecook/shell/posix'

class PosixTest < Test::Unit::TestCase
  include Linecook::Test
  
  attr_reader :recipe
  
  def setup
    super
    @recipe = Linecook::Recipe.new
    recipe.extend Linebook::Shell::Posix
  end
  
  def assert_recipe(expected, &block)
    recipe.instance_eval(&block)
    assert_output_equal expected, recipe.result(&block)
  end
  
  def assert_content(expected, name)
    recipe.close
    
    source_path = recipe.registry.invert[name]
    assert_output_equal expected, File.read(source_path)
  end
  
end