require File.expand_path('../../test_helper', __FILE__)
require 'linecook/package'
require 'linecook/test/file_test'

class PackageTest < Test::Unit::TestCase
  include Linecook::Test::FileTest
  
  Package = Linecook::Package
  
  attr_accessor :package
  
  def setup
    super
    @package = Package.new
  end
  
  #
  # context test
  #
  
  def test_context_returns_linecook_configs_in_env
    hash = {}
    package = Package.new('linecook' => hash)
    assert_equal hash.object_id, package.context.object_id
  end
  
  def test_context_initializes_to_empty_hash_if_unset
    assert_equal({}, package.context)
    assert_equal({}, package.env['linecook'])
  end
  
  #
  # registry test
  #
  
  def test_registry_returns_registry_in_context
    hash = {}
    package = Package.new('linecook' => {'registry' => hash})
    assert_equal hash.object_id, package.registry.object_id
  end
  
  def test_registry_initializes_to_empty_hash_if_unset
    assert_equal({}, package.registry)
    assert_equal({}, package.env['linecook']['registry'])
  end
  
  #
  # recipes test
  #
  
  def test_recipes_documentation
    package = Package.new('linecook' => {'package' => {'recipes' => 'a:b:c'}})
    assert_equal({'a' => 'a', 'b' => 'b', 'c' => 'c'}, package.recipes)
  end
  
  def test_recipes_returns_recipes_of_the_specified_type_in_configs
    hash = {}
    package = Package.new('linecook' => {'package' => {'recipes' => hash}})
    assert_equal hash.object_id, package.recipes.object_id
  end
  
  def test_recipes_initializes_to_empty_hash_if_unset
    assert_equal({}, package.recipes)
    assert_equal({}, package.env['linecook']['package']['recipes'])
  end
  
  def test_recipes_expands_array_into_a_redundant_hash
    package = Package.new('linecook' => {'package' => {'recipes' => ['a', 'b', 'c']}})
    
    assert_equal({'a' => 'a', 'b' => 'b', 'c' => 'c'}, package.recipes)
    assert_equal({'a' => 'a', 'b' => 'b', 'c' => 'c'}, package.env['linecook']['package']['recipes'])
  end
  
  def test_recipes_splits_string_into_a_redundant_hash_along_colons
    package = Package.new('linecook' => {'package' => {'recipes' => 'a:b:c'}})
    
    assert_equal({'a' => 'a', 'b' => 'b', 'c' => 'c'}, package.recipes)
    assert_equal({'a' => 'a', 'b' => 'b', 'c' => 'c'}, package.env['linecook']['package']['recipes'])
  end
  
  #
  # register test
  #
  
  def test_register_registers_source_file_to_target_file
    package.register('target/path', 'source/path')
    assert_equal File.expand_path('source/path'), package.registry['target/path']
  end
  
  def test_register_raises_error_for_target_registered_to_a_different_source
    package.register('target/path', 'source/a')
    
    err = assert_raises(RuntimeError) { package.register('target/path', 'source/b') }
    assert_equal 'already registered: "target/path"', err.message
  end

  def test_register_does_not_raise_error_for_double_register_of_same_source_and_target
    package.register('target/path', 'source/a')
    assert_nothing_raised { package.register('target/path', 'source/a') }
  end
  
  #
  # next_target_name test
  #
  
  def test_next_target_name_increments_target_name_if_already_registered
    assert_equal 'target/path',   package.next_target_name('target/path')
    
    package.register('target/path', 'source')
    assert_equal 'target/path.1', package.next_target_name('target/path')
    
    package.register('target/path.1', 'source')
    assert_equal 'target/path.2', package.next_target_name('target/path')
  end
  
  #
  # resource_path test
  #
  
  def test_resource_path_returns_corresponding_path_in_manifest
    package.manifest.replace('type' => {'path' => 'source/path'})
    assert_equal 'source/path', package.resource_path('type', 'path')
  end
  
  def test_resource_path_raises_error_for_unregistered_path
    err = assert_raises(RuntimeError) { package.resource_path('type', 'unknown/path') }
    assert_equal 'no such resource in manifest: "type" "unknown/path"', err.message
  end
  
  #
  # setup_tempfile test
  #
  
  def test_setup_tempfile_creates_registers_and_returns_a_new_tempfile
    tempfile = package.setup_tempfile('target/path')
    
    assert_equal Tempfile, tempfile.class
    assert_equal false, tempfile.closed?
  end
  
  def test_setup_tempfile_raises_error_if_target_name_is_already_registered
    package.register('target/path', 'source/b')
    err = assert_raises(RuntimeError) { package.setup_tempfile('target/path') }
    assert_equal 'already registered: "target/path"', err.message
  end
  
  #
  # tempfile_check test
  #
  
  def test_tempfile_check_returns_true_if_the_source_is_from_a_tempfile_setup_by_self
    assert_equal false, package.tempfile?('source/path')
    assert_equal true, package.tempfile?(package.setup_tempfile.path)
  end
  
  #
  # setup_recipe test
  #
  
  def test_setup_recipe_returns_a_new_recipe_that_builds_into_self
    recipe = package.setup_recipe
    recipe.target << 'content'
    
    recipe.close
    assert_equal 'content', package.content(recipe.target_name)
  end
  
  def test_recipes_set_up_by_self_close_on_package_close
    recipe = package.setup_recipe
    assert_equal false, recipe.closed?
    
    package.close
    assert_equal true, recipe.closed?
  end
  
  def test_setup_recipe_raises_error_if_target_name_is_already_registered
    package.register('target/path', 'source/path')
    err = assert_raises(RuntimeError) { package.setup_recipe('target/path') }
    assert_equal 'already registered: "target/path"', err.message
  end
  
  #
  # next_variable_name test
  #
  
  def test_next_variable_name_increments_and_returns_context
    assert_equal 'a0', package.next_variable_name('a')
    assert_equal 'a1', package.next_variable_name('a')
    assert_equal 'b0', package.next_variable_name('b')
  end
  
  def test_next_variable_name_converts_context_to_a_string
    assert_equal 'a0', package.next_variable_name('a')
    assert_equal 'a1', package.next_variable_name(:a)
    assert_equal 'a2', package.next_variable_name('a')
  end
  
  #
  # build_file test
  #
  
  def test_build_file_looks_up_and_registers_the_specified_file
    package.manifest.replace('files' => {
      'name' => prepare('example') {|io| io << 'content' }
    })
    
    package.build_file('target/path', 'name')
    assert_equal 'content', package.content('target/path')
  end
  
  def test_build_file_raises_error_if_no_such_file_is_in_manifest
    err = assert_raises(RuntimeError) { package.build_file('target/path', 'name') }
    assert_equal 'no such resource in manifest: "files" "name"', err.message
  end
  
  def test_build_file_raises_error_if_the_target_is_already_registered
    package.manifest.replace('files' => {'name' => 'file/path'})
    package.register('target/path', 'source/path')
    
    err = assert_raises(RuntimeError) { package.build_file('target/path', 'name') }
    assert_equal 'already registered: "target/path"', err.message
  end
  
  def test_build_file_returns_package
    package.manifest.replace('files' => {
      'name' => prepare('example') {|io| io << 'content' }
    })
    assert_equal package, package.build_file('target/path', 'name')
  end
  
  #
  # build_template test
  #
  
  def test_build_template_looks_up_builds_and_registers_the_specified_template
    package.manifest.replace('templates' => {
      'name' => prepare('example') {|io| io << 'got: <%= key %>'}
    })
    
    package.build_template('target/path', 'name', 'key' => 'value')
    assert_equal 'got: value', package.content('target/path')
  end
  
  def test_build_template_uses_env_as_locals_by_default
    package.manifest.replace('templates' => {
      'name' => prepare('example') {|io| io << 'got: <%= key %>'}
    })
    
    package.env['key'] = 'value'
    package.build_template('target/path', 'name')
    assert_equal 'got: value', package.content('target/path')
  end
  
  def test_build_template_raises_error_if_no_such_template_is_in_manifest
    err = assert_raises(RuntimeError) { package.build_template('target/path', 'name') }
    assert_equal 'no such resource in manifest: "templates" "name"', err.message
  end
  
  def test_build_template_raises_error_if_the_target_is_already_registered
    package.manifest.replace('templates' => {'name' => prepare('template') {}})
    package.register('target/path', 'source/path')
    
    err = assert_raises(RuntimeError) { package.build_template('target/path', 'name') }
    assert_equal 'already registered: "target/path"', err.message
  end
  
  def test_build_template_returns_package
    package.manifest.replace('templates' => {'name' => prepare('template') {}})
    assert_equal package, package.build_template('target/path', 'name')
  end
  
  #
  # build_recipe test
  #
  
  def test_build_recipe_looks_up_evaluates_and_registers_the_specified_recipe
    package.manifest.replace('recipes' => {
      'name' => prepare('example') {|io| io << 'target << "content"'}
    })
    
    package.build_recipe('target/path', 'name')
    assert_equal 'content', package.content('target/path')
  end
  
  def test_build_recipe_raises_error_if_no_such_recipe_is_in_manifest
    err = assert_raises(RuntimeError) { package.build_recipe('target/path', 'name') }
    assert_equal 'no such resource in manifest: "recipes" "name"', err.message
  end
  
  def test_build_recipe_raises_error_if_the_target_is_already_registered
    package.manifest.replace('recipes' => {
      'name' => prepare('example') {|io| io << 'target << "content"'}
    })
    package.register('target/path', 'source/path')
    
    err = assert_raises(RuntimeError) { package.build_recipe('target/path', 'name') }
    assert_equal 'already registered: "target/path"', err.message
  end
  
  def test_build_recipe_returns_package
    package.manifest.replace('recipes' => {'name' => prepare('example') {|io| io << ''}})
    assert_equal package, package.build_recipe('target/path', 'name')
  end
  
  #
  # content test
  #
  
  def test_content_returns_the_contents_of_the_target
    tempfile = Tempfile.new('example')
    tempfile << 'content'
    tempfile.close
    
    package.register 'target/path', tempfile.path
    assert_equal 'content', package.content('target/path')
  end
  
  def test_content_returns_the_specified_length_and_offset
    tempfile = Tempfile.new('example')
    tempfile << 'content'
    tempfile.close
    
    package.register 'target/path', tempfile.path
    assert_equal 'nte', package.content('target/path', 3, 2)
  end
  
  def test_content_returns_nil_for_unregistered_target
    assert_equal nil, package.content('not/registered')
  end
  
  #
  # export test
  #
  
  def test_export_copies_source_files_to_dir_as_specified_in_registry
    original_source = prepare('example') {|io| io << 'content'}
    
    package.registry['target/path'] = original_source
    package.export path('export/dir')
    
    assert_equal 'content', File.read(original_source)
    assert_equal 'content', File.read(path('export/dir/target/path'))
  end
  
  def test_export_moves_tempfiles_specified_in_registry
    tempfile = package.setup_tempfile('target/path')
    tempfile << 'content'
    
    package.export path('export/dir')
    
    assert_equal false, File.exists?(tempfile.path)
    assert_equal 'content', File.read(path('export/dir/target/path'))
  end
  
  def test_export_rewrites_and_returns_registry_with_new_source_paths
    tempfile = package.setup_tempfile('target/path')
    assert_equal tempfile.path, package.registry['target/path']
    
    registry = package.export path('export/dir')
    assert_equal path('export/dir/target/path'), registry['target/path']
  end
end