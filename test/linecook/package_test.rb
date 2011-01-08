require File.expand_path('../../test_helper', __FILE__)
require 'linecook/package'

class PackageTest < Test::Unit::TestCase
  Package = Linecook::Package
  
  attr_accessor :package
  
  def setup
    @package = Package.new
  end
  
  #
  # config test
  #
  
  def test_config_returns_configs_in_env
    hash = {}
    package = Package.new(Package::CONFIG_KEY => hash)
    assert_equal hash.object_id, package.config.object_id
  end
  
  def test_config_initializes_to_empty_hash_if_unset
    assert_equal({}, package.config)
    assert_equal({}, package.env[Package::CONFIG_KEY])
  end
  
  #
  # recipes test
  #
  
  def test_recipes_returns_recipes_in_configs
    hash = {}
    package = Package.new(Package::CONFIG_KEY => {Package::RECIPES_KEY => hash})
    assert_equal hash.object_id, package.recipes.object_id
  end
  
  def test_recipes_initializes_to_empty_hash_if_unset
    assert_equal({}, package.recipes)
    assert_equal({}, package.env[Package::CONFIG_KEY][Package::RECIPES_KEY])
  end
  
  def test_recipes_expands_array_recipes_into_a_redundant_hash
    package = Package.new(Package::CONFIG_KEY => {Package::RECIPES_KEY => ['a', 'b', 'c']})
    
    assert_equal({'a' => 'a', 'b' => 'b', 'c' => 'c'}, package.recipes)
    assert_equal({'a' => 'a', 'b' => 'b', 'c' => 'c'}, package.env[Package::CONFIG_KEY][Package::RECIPES_KEY])
  end
  
  #
  # register! test
  #
  
  def test_register_bang_registers_source_file_to_target_file
    source_path = File.expand_path('source/path')
    target_path = 'target/path'
    
    package.register!(target_path, source_path)
    
    assert_equal source_path, package.registry[target_path]
    assert_equal target_path, package.reverse_registry[source_path]
  end
  
  def test_register_bang_expands_source_path
    package.register!('target/path', 'source/path')
    assert_equal File.expand_path('source/path'), package.registry['target/path']
  end
  
  def test_register_bang_raises_error_for_target_registered_to_a_different_source
    package.register!('target/path', 'source/a')
    
    err = assert_raises(RuntimeError) { package.register!('target/path', 'source/b') }
    assert_equal 'already registered: "target/path"', err.message
  end

  def test_register_bang_does_not_raise_error_for_double_register_of_same_source_and_target
    package.register!('target/path', 'source/a')
    assert_nothing_raised { package.register!('target/path', 'source/a') }
  end
end