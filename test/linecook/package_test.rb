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
    assert_equal hash, package.config
  end
  
  def test_config_initializes_to_empty_hash_if_unset
    assert_equal({}, package.config)
    assert_equal({}, package.env[Package::CONFIG_KEY])
  end
  
  #
  # manifest test
  #
  
  def test_manifest_returns_manifest_in_configs
    hash = {}
    package = Package.new(Package::CONFIG_KEY => {Package::MANIFEST_KEY => hash})
    assert_equal hash, package.manifest
  end
  
  def test_manifest_initializes_to_empty_hash_if_unset
    assert_equal({}, package.manifest)
    assert_equal({}, package.env[Package::CONFIG_KEY][Package::MANIFEST_KEY])
  end
  
  #
  # recipes test
  #
  
  def test_recipes_returns_recipes_in_configs
    hash = {}
    package = Package.new(Package::CONFIG_KEY => {Package::RECIPES_KEY => hash})
    assert_equal hash, package.recipes
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
end