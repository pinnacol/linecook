require File.expand_path('../../test_helper', __FILE__)
require 'linecook/package'
require 'tempfile'
require 'ostruct'

class PackageTest < Test::Unit::TestCase
  include ShellTest

  Package = Linecook::Package

  attr_accessor :package

  def setup
    super
    @package = Package.new
  end

  #
  # resolve_source_path test
  #

  def test_resolve_source_path_resolves_sources_to_path_using_path_method
    source = OpenStruct.new :path => '/source/path'
    assert_equal '/source/path', package.resolve_source_path(source)
  end

  def test_resolve_source_path_uses_source_as_path_if_it_does_not_have_a_path_method
    assert_equal '/source/path', package.resolve_source_path('/source/path')
  end

  def test_resolve_source_path_expands_path
    assert_equal File.expand_path('source/path'), package.resolve_source_path('source/path')
  end

  #
  # register test
  #

  def test_register_registers_source_to_target_path
    package.register('target/path', 'source/path')
    assert_equal File.expand_path('source/path'), package.registry['target/path']
  end

  def test_register_raises_error_for_target_path_registered_to_a_different_source
    package.register('target/path', 'source/a')

    err = assert_raises(RuntimeError) { package.register('target/path', 'source/b') }
    assert_equal %{already registered: "target/path" ("#{File.expand_path('source/a')}")}, err.message
  end

  def test_register_does_not_raise_error_for_double_register_of_same_source_and_target_path
    package.register('target/path', 'source/a')
    assert_nothing_raised { package.register('target/path', 'source/a') }
  end

  def test_register_checks_resolved_source_paths_to_determine_target_path_conflict
    source = Tempfile.new('source')
    package.register('target/path', source.path)
    assert_nothing_raised { package.register('target/path', source) }
  end

  def test_register_accepts_export_options
    package.register('target/path', 'source/path', :move => true)
    assert_equal true, package.export_options('target/path')[:move]
  end

  #
  # unregister test
  #

  def test_unregister_removes_source_path_from_registry
    package.register('target/a', 'source/one')
    package.register('target/b', 'source/one')
    package.register('target/c', 'source/two')
    package.unregister('source/one')

    assert_equal({'target/c' => File.expand_path('source/two')}, package.registry)
  end

  def test_unregister_resolves_source_to_source_path
    source = Tempfile.new('source')
    package.register('target/path', source.path)
    package.unregister(source)

    assert_equal false, package.registry.has_key?('target/path')
  end

  #
  # add test
  #

  def test_add_adds_and_returns_a_tempfile_at_the_specified_target_path
    tempfile = package.add('target/path')
    assert_equal Tempfile, tempfile.class
    assert_equal false, tempfile.closed?
    assert_equal tempfile.path, package.source_path('target/path')
  end

  def test_added_tempfiles_are_marked_for_move_by_default
    package.add('target/path')
    assert_equal true, package.export_options('target/path')[:move]
  end

  def test_add_accepts_export_options
    package.add('target/path', :mode => 0640)
    assert_equal 0640, package.export_options('target/path')[:mode]
  end

  #
  # rm test
  #

  def test_rm_removes_target_path_from_registry
    package.register('target/path', 'source/a')
    package.rm('target/path')
    assert_equal false, package.registry.has_key?('target/path')
  end

  #
  # source_path test
  #

  def test_source_path_returns_the_source_path_registered_to_the_target_path
    source = package.add('target/path')
    assert_equal source.path, package.source_path('target/path') 
  end

  def test_source_path_returns_nil_if_nothing_is_registered_to_target_path
    assert_equal nil, package.source_path('target/path')
  end

  #
  # target_paths test
  #

  def test_target_paths_returns_all_target_paths_that_register_the_source
    source_path = path('source/path')
    package.register('target/a', source_path)
    package.register('target/b', source_path)
    assert_equal ['target/a', 'target/b'], package.target_paths(source_path)
  end

  #
  # content test
  #

  def test_content_returns_the_contents_of_the_target
    source_path = prepare('source', 'content')
    package.register 'target/path', source_path
    assert_equal 'content', package.content('target/path')
  end

  def test_content_flushes_source_if_applicable
    source = Tempfile.new 'source'
    package.register 'target/path', source
    source << 'content'
    assert_equal 'content', package.content('target/path')
  end

  def test_content_returns_the_specified_length_and_offset
    source_path = prepare('source', 'content')
    package.register 'target/path', source_path
    assert_equal 'nte', package.content('target/path', 3, 2)
  end

  def test_content_returns_the_specified_length_and_offset_for_source
    source = Tempfile.new 'source'
    package.register 'target/path', source
    source << 'content'
    assert_equal 'nte', package.content('target/path', 3, 2)
  end

  def test_content_returns_nil_for_unregistered_target
    assert_equal nil, package.content('not/added')
  end

  #
  # callback test
  #

  def test_callback_registers_and_returns_a_stringio
    stringio = package.callback('name')
    assert_equal StringIO, stringio.class
    assert_equal false, stringio.closed?
    assert_equal stringio, package.callbacks['name']
  end

  #
  # next_target_path test
  #

  def test_next_target_path_increments_target_name_if_already_registered
    assert_equal 'target/path',   package.next_target_path('target/path')

    package.register('target/path', 'source')
    assert_equal 'target/path.1', package.next_target_path('target/path')

    package.register('target/path.1', 'source')
    assert_equal 'target/path.2', package.next_target_path('target/path')
  end

  #
  # close test
  #

  def test_close_closes_open_sources_in_registry
    a = package.add('a')
    b = package.add('b')
    a.close

    assert a.closed?
    assert !b.closed?

    package.close

    assert a.closed?
    assert b.closed?
  end

  def test_close_returns_self
    assert_equal package, package.close
  end

  #
  # on_export test
  #

  def test_on_export_sets_export_options_for_target_path
    package.on_export('target/path', :move => true)
    assert_equal({:move => true}, package.export_options('target/path'))
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

  def test_export_moves_sources_for_targets_marked_for_move
    source_path = prepare('source', 'content')
    package.register('target/path', source_path, :move => true)
    package.export path('export/dir')

    assert_equal false, File.exists?(source_path)
    assert_equal 'content', File.read(path('export/dir/target/path'))
  end

  def test_export_sets_the_mode_for_the_target_as_specified_in_export_options
    source_path = prepare('source', 'content')
    package.register('target/path', source_path, :mode => 0640)
    package.export path('export/dir')

    assert_equal '100640', mode('export/dir/target/path')
  end

  def test_export_rewrites_and_returns_registry_with_new_source_paths
    source_path = prepare('source', 'content')
    package.register('target/path', source_path)
    registry = package.export path('export/dir')

    assert_equal path('export/dir/target/path'), registry['target/path']
  end

  def test_export_can_be_used_to_update_an_export
    source_path = prepare('source', 'content')
    package.register('target/path', source_path)

    package.on_export('target/path', :mode => 0640)
    package.export path('export/dir')

    package.on_export('target/path', :mode => 0600)
    package.export path('export/dir')

    assert_equal '100600', mode('export/dir/target/path')
  end

  def test_export_uses_default_export_options
    source_path = prepare('source', 'content')
    package.register('target/path', source_path)
    package.default_export_options[:mode] = 0640
    package.export path('export/dir')

    assert_equal '100640', mode('export/dir/target/path')
  end

  def test_export_closes_package
    a = package.add('a')
    a << 'content'
    package.export path('export/dir')
    assert a.closed?
    assert_equal 'content', content('export/dir/a')
  end

  def test_export_allows_export_into_existing_directory
    prepare 'dir/a', 'a'
    package.add('b') << 'b'

    package.export path('dir')
    assert_equal 'a', content('dir/a')
    assert_equal 'b', content('dir/b')
  end

  def test_export_raises_error_for_existing_file
    previous = prepare 'dir/file', 'previous'
    current  = package.add('file')
    current << 'current'

    err = assert_raises(RuntimeError) { package.export path('dir') }
    assert_equal "already exists: #{path('dir/file').inspect}", err.message
    assert_equal 'previous', content('dir/file')
  end

  def test_export_continues_export_if_block_returns_true_for_existing_file
    previous = prepare 'dir/file', 'previous'
    current  = package.add('file')
    current << 'current'

    package.export path('dir') do |src, dest|
      true
    end

    assert_equal 'current', content('dir/file')
  end

  def test_export_skips_if_block_returns_false_for_existing_file
    previous = prepare 'dir/file', 'previous'
    current  = package.add('file')
    current << 'current'

    package.export path('dir') do |src, dest|
      false
    end

    assert_equal 'previous', content('dir/file')
  end
end