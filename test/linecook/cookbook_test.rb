require File.expand_path('../../test_helper', __FILE__)
require 'linecook/cookbook'

class CookbookTest < Test::Unit::TestCase
  include ShellTest::FileMethods
  Cookbook = Linecook::Cookbook

  attr_accessor :cookbook

  def setup
    super
    @cookbook = Cookbook.new
  end

  #
  # path test
  #

  def test_path_returns_the_path_for_type
    cookbook.paths[:type] = ['a', 'b']
    assert_equal ['a', 'b'], cookbook.path(:type)
  end

  def test_path_sets_empty_array_for_unknown_types
    path = cookbook.path(:type)
    assert_equal [], path
    path << 'a'
    assert_equal ['a'], cookbook.paths[:type]
  end

  #
  # add test
  #

  def test_add_expands_and_pushes_dir_onto_path_for_type
    cookbook.add :type, 'a'
    cookbook.add :type, 'b'
    assert_equal [File.expand_path('a'), File.expand_path('b')], cookbook.path(:type)
  end

  #
  # rm test
  #

  def test_rm_deletes_expanded_dir_from_path_for_type
    cookbook.add :type, 'a'
    cookbook.add :type, 'b'
    cookbook.add :type, 'c'
    cookbook.rm  :type, 'b'
    assert_equal [File.expand_path('a'), File.expand_path('c')], cookbook.path(:type)
  end

  #
  # find test
  #

  def test_find_returns_existing_absolute_paths
    path = prepare('file', '')
    assert_equal path, File.expand_path(path)
    assert_equal path, cookbook.find(:type, path)
  end

  def test_find_returns_nil_for_non_existing_absolute_paths
    path = File.expand_path('file')
    assert_equal false, File.exists?(path)
    assert_equal nil, cookbook.find(:type, path)
  end

  def test_find_searches_paths_of_the_given_type_for_the_file
    cookbook.paths[:type] = [path('a'), path('b')]
    b = prepare('b/file')
    assert_equal b, cookbook.find(:type, 'file')
  end

  def test_find_returns_first_existing_path
    cookbook.paths[:type] = [path('a'), path('b')]
    a = prepare('a/file')
    b = prepare('b/file')
    assert_equal a, cookbook.find(:type, 'file')
  end

  def test_find_checks_each_extname_if_no_full_path_is_found
    cookbook.paths[:type] = [path('a')]
    a = prepare('a/file.txt')
    b = prepare('a/script.rb')
    assert_equal a, cookbook.find(:type, 'file', ['.txt', '.rb'])
    assert_equal b, cookbook.find(:type, 'script', ['.txt', '.rb'])
  end

  def test_find_checks_each_extname_vs_a_path_before_checking_other_paths
    cookbook.paths[:type] = [path('a'), path('b')]
    a = prepare('a/file.txt')
    b = prepare('b/file')
    assert_equal a, cookbook.find(:type, 'file', ['.txt'])
  end

  def test_find_returns_nil_if_no_file_is_found
    cookbook.paths[:type] = [path('a')]
    assert_equal nil, cookbook.find(:type, 'file')
  end

  def test_find_raises_no_error_if_no_paths_for_the_type_are_registered
    assert_equal nil, cookbook.find(:type, 'file')
  end
end