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
  # resources test
  #
  
  def test_resources_documentation
    package = Package.new('linecook' => {'recipes' => 'a:b:c'})
    assert_equal({'a' => 'a', 'b' => 'b', 'c' => 'c'}, package.resources('recipes'))
  end
  
  def test_resources_returns_resources_of_the_specified_type_in_configs
    hash = {}
    package = Package.new(Package::CONFIG_KEY => {Package::RECIPES_KEY => hash})
    assert_equal hash.object_id, package.resources(Package::RECIPES_KEY).object_id
  end
  
  def test_resources_initializes_to_empty_hash_if_unset
    assert_equal({}, package.resources(Package::RECIPES_KEY))
    assert_equal({}, package.env[Package::CONFIG_KEY][Package::RECIPES_KEY])
  end
  
  def test_resources_expands_array_into_a_redundant_hash
    package = Package.new(Package::CONFIG_KEY => {Package::RECIPES_KEY => ['a', 'b', 'c']})
    
    assert_equal({'a' => 'a', 'b' => 'b', 'c' => 'c'}, package.resources(Package::RECIPES_KEY))
    assert_equal({'a' => 'a', 'b' => 'b', 'c' => 'c'}, package.env[Package::CONFIG_KEY][Package::RECIPES_KEY])
  end
  
  def test_resources_splits_string_into_a_redundant_hash_along_colons
    package = Package.new(Package::CONFIG_KEY => {Package::RECIPES_KEY => 'a:b:c'})
    
    assert_equal({'a' => 'a', 'b' => 'b', 'c' => 'c'}, package.resources(Package::RECIPES_KEY))
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
  
  #
  # register test
  #
  
  def test_register_increments_target_path_if_already_registered
    source_path_a = File.expand_path('source/a')
    source_path_b = File.expand_path('source/b')
    
    assert_equal 'target/path',   package.register('target/path', source_path_a)
    assert_equal 'target/path.1', package.register('target/path', source_path_b)
    
    assert_equal source_path_a, package.registry['target/path']
    assert_equal source_path_b, package.registry['target/path.1']
  end
  
  #
  # registered_target check test
  #
  
  def test_registered_target_check_returns_true_if_the_target_is_registered
    assert_equal false, package.registered_target?('target/path')
    package.register('target/path', 'source/path')
    assert_equal true, package.registered_target?('target/path')
  end
  
  #
  # registered_source check test
  #
  
  def test_registered_source_check_returns_true_if_the_source_is_registered
    assert_equal false, package.registered_source?('source/path')
    package.register('target/path', 'source/path')
    assert_equal true, package.registered_source?('source/path')
  end
  
  #
  # target_path test
  #
  
  def test_target_path_returns_the_latest_target_path_registerd_to_source
    assert_equal nil, package.target_path('source/path')
    
    package.register('target/path/a', 'source/path')
    assert_equal 'target/path/a', package.target_path('source/path')
    
    package.register('target/path/b', 'source/path')
    assert_equal 'target/path/b', package.target_path('source/path')
  end
  
  #
  # source_path test
  #
  
  def test_source_path_returns_the_source_path_registerd_to_target
    assert_equal nil, package.source_path('target/path')
    
    package.register('target/path', 'source/path')
    assert_equal File.expand_path('source/path'), package.source_path('target/path')
  end
  
  #
  # resource_path test
  #
  
  def test_resource_path_returns_corresponding_path_in_manifest
    package.manifest['path'] = 'source/path'
    assert_equal 'source/path', package.resource_path('path')
  end
  
  def test_resource_path_joins_path_segments
    package.manifest['nest/path'] = 'source/path'
    assert_equal 'source/path', package.resource_path('nest', 'path')
  end
  
  def test_resource_path_raises_error_for_unregistered_path
    err = assert_raises(RuntimeError) { package.resource_path('unknown/path') }
    assert_equal 'no such resource in manifest: "unknown/path"', err.message
  end
  
  #
  # tempfile test
  #
  
  def test_tempfile_creates_registers_and_returns_a_new_tempfile
    tempfile = package.tempfile('target/path')
    
    assert_equal Tempfile, tempfile.class
    assert_equal false, tempfile.closed?
    assert_equal 'target/path', package.target_path(tempfile.path)
  end
  
  def test_tempfile_increments_target_path_as_needed
    a = package.tempfile('target/path')
    b = package.tempfile('target/path')
    
    assert_equal 'target/path', package.target_path(a.path)
    assert_equal 'target/path.1', package.target_path(b.path)
  end
  
  #
  # tempfile! test
  #
  
  def test_tempfile_bang_raises_error_if_target_path_is_already_registered
    package.register('target/path', 'source/b')
    err = assert_raises(RuntimeError) { package.tempfile!('target/path') }
    assert_equal 'already registered: "target/path"', err.message
  end
  
  #
  # tempfile_check test
  #
  
  def test_tempfile_check_returns_true_if_the_source_is_from_a_tempfile_generated_by_self
    assert_equal false, package.tempfile?('source/path')
    assert_equal true, package.tempfile?(package.tempfile.path)
  end
  
  #
  # recipe test
  #
  
  def test_recipe_returns_a_new_recipe_that_builds_into_self
    recipe = package.recipe
    recipe.target << 'content'
    recipe.close
    
    assert_equal 'content', package.content(recipe.target_name)
  end
  
  def test_recipe_increments_target_path_as_needed
    a = package.recipe('target/path')
    b = package.recipe('target/path')
    
    assert_equal 'target/path',   a.target_path
    assert_equal 'target/path.1', b.target_path
  end
  
  def test_recipes_close_with_package
    recipe = package.recipe
    assert_equal false, recipe.closed?
    
    package.close
    assert_equal true, recipe.closed?
  end
  
  #
  # recipe! test
  #
  
  def test_recipe_bang_raises_error_if_target_path_is_already_registered
    package.register('target/path', 'source/path')
    err = assert_raises(RuntimeError) { package.recipe!('target/path') }
    assert_equal 'already registered: "target/path"', err.message
  end
end