require File.expand_path('../../test_helper', __FILE__)
require 'linecook/package'
require 'tempfile'

class PackageTest < Test::Unit::TestCase
  include ShellTest

  Package = Linecook::Package

  attr_accessor :package

  def setup
    super
    @package = Package.new
  end

  #
  # add test
  #

  def test_add_registers_source_file_to_target_name
    package.add('target/path', 'source/path')
    assert_equal File.expand_path('source/path'), package.registry['target/path']
  end

  def test_add_raises_error_for_target_name_added_to_a_different_source
    package.add('target/path', 'source/a')

    err = assert_raises(RuntimeError) { package.add('target/path', 'source/b') }
    assert_equal %{already registered: "target/path" ("#{File.expand_path('source/a')}")}, err.message
  end

  def test_add_does_not_raise_error_for_double_add_of_same_source_and_target_name
    package.add('target/path', 'source/a')
    assert_nothing_raised { package.add('target/path', 'source/a') }
  end

  #
  # content test
  #

  def test_content_returns_the_contents_of_the_target
    source_path = prepare('source', 'content')
    package.add 'target/path', source_path
    assert_equal 'content', package.content('target/path')
  end

  def test_content_returns_the_specified_length_and_offset
    source_path = prepare('source', 'content')
    package.add 'target/path', source_path
    assert_equal 'nte', package.content('target/path', 3, 2)
  end

  def test_content_returns_nil_for_unadded_target
    assert_equal nil, package.content('not/added')
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

  def test_export_moves_sources_marked_for_move_on_export
    source_path = prepare('source', 'content')
    package.add('target/path', source_path)
    package.move_on_export(source_path)

    package.export path('export/dir')

    assert_equal false, File.exists?(source_path)
    assert_equal 'content', File.read(path('export/dir/target/path'))
  end

  def test_export_rewrites_and_returns_registry_with_new_source_paths
    source_path = prepare('source', 'content')
    package.add('target/path', source_path)
    registry = package.export path('export/dir')
    assert_equal path('export/dir/target/path'), registry['target/path']
  end
end