require File.expand_path('../../test_helper', __FILE__)
require 'linecook/script'

class ScriptTest < Test::Unit::TestCase
  Script = Linecook::Script
  
  attr_accessor :script
  
  def setup
    @script = Script.new
  end
  
  #
  # config test
  #
  
  def test_config_returns_configs_in_context
    hash = {}
    script = Script.new(Script::CONFIG_KEY => hash)
    assert_equal hash, script.config
  end
  
  def test_config_initializes_to_empty_hash_if_unset
    assert_equal({}, script.config)
    assert_equal({}, script.context[Script::CONFIG_KEY])
  end
  
  #
  # manifest test
  #
  
  def test_manifest_returns_manifest_in_configs
    hash = {}
    script = Script.new(Script::CONFIG_KEY => {Script::MANIFEST_KEY => hash})
    assert_equal hash, script.manifest
  end
  
  def test_manifest_initializes_to_empty_hash_if_unset
    assert_equal({}, script.manifest)
    assert_equal({}, script.context[Script::CONFIG_KEY][Script::MANIFEST_KEY])
  end
  
  #
  # recipes test
  #
  
  def test_recipes_returns_recipes_in_configs
    hash = {}
    script = Script.new(Script::CONFIG_KEY => {Script::RECIPES_KEY => hash})
    assert_equal hash, script.recipes
  end
  
  def test_recipes_initializes_to_empty_hash_if_unset
    assert_equal({}, script.recipes)
    assert_equal({}, script.context[Script::CONFIG_KEY][Script::RECIPES_KEY])
  end
  
  def test_recipes_expands_array_recipes_into_a_redundant_hash
    script = Script.new(Script::CONFIG_KEY => {Script::RECIPES_KEY => ['a', 'b', 'c']})
    
    assert_equal({'a' => 'a', 'b' => 'b', 'c' => 'c'}, script.recipes)
    assert_equal({'a' => 'a', 'b' => 'b', 'c' => 'c'}, script.context[Script::CONFIG_KEY][Script::RECIPES_KEY])
  end
  
  #
  # registry test
  #
  
  def test_registry_returns_registry_in_configs
    hash = {}
    script = Script.new(Script::CONFIG_KEY => {Script::REGISTRY_KEY => hash})
    assert_equal hash, script.registry
  end
  
  def test_registry_initializes_to_empty_hash_if_unset
    assert_equal({}, script.registry)
    assert_equal({}, script.context[Script::CONFIG_KEY][Script::REGISTRY_KEY])
  end
  
  #
  # attributes test
  #
  
  def test_attributes_returns_new_attributes_with_context
    attributes = script.attributes
    assert_equal script.context, attributes.context
  end
  
  #
  # tempfile test
  #
  
  def test_tempfile_returns_a_tempfile
    tempfile = script.tempfile('rp')
    assert_equal Tempfile, tempfile.class
  end
  
  def test_tempfile_registers_tempfile_in_registry_using_relative_path
    tempfile = script.tempfile('rp')
    assert_equal 'rp', script.registry[tempfile.path]
  end
  
  def test_tempfile_caches_reference_to_tempfile
    tempfile = script.tempfile('rp')
    assert_equal true, script.cache.include?(tempfile)
  end
  
  #
  # register test
  #
  
  def test_register_records_relative_path_in_registry_using_source_path
    script.register 'source/path', 'relative/path'
    assert_equal 'relative/path', script.registry['source/path']
  end
  
  def test_register_uses_basename_of_source_as_default_relative_path
    script.register 'source/path'
    assert_equal 'path', script.registry['source/path']
  end
  
  def test_register_ensures_relative_path_is_unique
    script.register 'source/a', 'relative/path'
    script.register 'source/b', 'relative/path'
    
    assert_equal 'relative/path', script.registry['source/a']
    assert_equal 'relative/path.1', script.registry['source/b']
  end
  
  def test_register_nests_relative_path_under_current_scope
    script.with_scope 'scope' do
      script.register 'source/path', 'relative/path'
    end
    
    assert_equal 'scope/relative/path', script.registry['source/path']
  end
  
  def test_register_raises_error_for_already_registered_source
    script.register 'source/path', 'relative/path'
    err = assert_raises(RuntimeError) { script.register 'source/path', 'relative/path' }
    assert_equal 'already registered: "source/path"', err.message
  end
  
  #
  # with_scope test
  #
  
  def test_with_scope_sets_scope_for_duration_of_block
    scope = nil
    
    script.with_scope('scope') do
      scope = script.scope
    end
    
    assert_equal 'scope', scope
  end
  
  def test_with_scopes_may_be_nested
    a1, a2, b = nil, nil, nil
    
    script.with_scope('a') do
      a1 = script.scope
      script.with_scope('b') do
        b = script.scope
      end
      a2 = script.scope
    end
    
    assert_equal 'a', a1
    assert_equal 'a', a2
    assert_equal 'b', b
  end
end