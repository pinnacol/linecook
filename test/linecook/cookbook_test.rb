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
  # initialize test
  #

  def test_initialize_adds_each_project_dir
    cookbook = Cookbook.new path('a'), path('b')
    assert_equal [path('a'), path('b')], cookbook.project_dirs
    assert_equal [path('a/attributes'), path('b/attributes')], cookbook.path(:attributes)
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
  # add_project_dir test
  #

  def test_add_project_dir_adds_path_for_each_of_project_paths
    cookbook.project_paths[:type] = 'dir'
    cookbook.add_project_dir 'a'
    assert_equal [File.expand_path('a/dir')], cookbook.path(:type)
  end

  def test_add_project_dir_adds_path_to_project_dirs
    cookbook.add_project_dir 'a'
    assert_equal [File.expand_path('a')], cookbook.project_dirs
  end

  def test_add_project_dir_loads_cookbook_file_for_project_paths_if_it_exists
    cookbook.project_paths[:type] = 'dir'
    prepare 'cookbook.yml', 'type: alt'
    cookbook.add_project_dir method_dir
    assert_equal [path('alt')], cookbook.path(:type)
  end

  def test_add_project_dir_assumes_default_paths_if_cookbook_file_loads_to_nil
    cookbook.project_paths[:type] = 'dir'
    prepare 'cookbook.yml', ''
    cookbook.add_project_dir method_dir
    assert_equal [path('dir')], cookbook.path(:type)
  end

  #
  # rm_project_dir test
  #

  def test_rm_project_dir_removes_path_for_each_of_project_paths
    cookbook.project_paths[:type] = 'dir'
    cookbook.add :type, 'a/dir'
    cookbook.rm_project_dir 'a'

    assert_equal [], cookbook.path(:type)
  end

  def test_rm_project_dir_removes_path_from_project_dirs
    cookbook.add :projects, 'a'
    cookbook.rm_project_dir 'a'
    assert_equal [], cookbook.project_dirs
  end

  def test_rm_project_dir_loads_cookbook_file_for_project_paths_if_it_exists
    cookbook.project_paths[:type] = 'dir'
    cookbook.add :type, path('alt')
    prepare 'cookbook.yml', 'type: alt'

    cookbook.rm_project_dir method_dir
    assert_equal [], cookbook.path(:type)
  end

  #
  # bulk_add test
  #

  def test_bulk_add_concats_paths_for_each_type
    cookbook.add :one, 'a'
    cookbook.add :two, 'b'
    cookbook.bulk_add :two => ['B'], :three => ['C']

    assert_equal [File.expand_path('a')], cookbook.path(:one)
    assert_equal [File.expand_path('b'), File.expand_path('B')], cookbook.path(:two)
    assert_equal [File.expand_path('C')], cookbook.path(:three)
  end

  def test_bulk_add_allows_single_values
    cookbook.bulk_add :one => 'a'
    assert_equal [File.expand_path('a')], cookbook.path(:one)
  end

  #
  # bulk_rm test
  #

  def test_bulk_rm_removes_paths_for_each_type
    cookbook.add :one, 'a'
    cookbook.add :one, 'A'
    cookbook.add :two, 'b'
    cookbook.bulk_rm :one => ['a'], :two => ['b']

    assert_equal [File.expand_path('A')], cookbook.path(:one)
    assert_equal [], cookbook.path(:three)
  end

  def test_bulk_rm_allows_single_values
    cookbook.add :one, 'a'
    cookbook.bulk_rm :one => 'a'
    assert_equal [], cookbook.path(:one)
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