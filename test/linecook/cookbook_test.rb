require File.expand_path('../../test_helper', __FILE__)
require 'linecook/cookbook'

class CookbookTest < Test::Unit::TestCase
  include ShellTest::FileMethods
  Cookbook = Linecook::Cookbook

  attr_accessor :cookbook

  def setup
    super
    @cookbook = Cookbook.new path('a'), path('b')
  end

  #
  # initialize test
  #

  def test_initialize_sets_path
    cookbook = Cookbook.new path('a'), path('b')
    assert_equal [path('a'), path('b')], cookbook.paths
  end

  def test_initialize_adds_mappings_to_path
    cookbook = Cookbook.new({:dir => path('a')})
    assert_equal [{:dir => path('a')}], cookbook.paths
  end

  def test_initialize_expands_dir_mapping_arrays
    cookbook = Cookbook.new [method_dir, {:dir => 'a'}]
    assert_equal [{:dir => path('a')}], cookbook.paths
  end

  #
  # add test
  #

  def test_add_pushes_expanded_dir_onto_path
    cookbook = Cookbook.new
    cookbook.add 'a'
    cookbook.add 'b'
    assert_equal [File.expand_path('a'), File.expand_path('b')], cookbook.paths
  end

  def test_add_expands_mappings_and_adds_the_result_to_path
    cookbook = Cookbook.new
    cookbook.add 'a', :type => 'one'
    assert_equal [{:type => File.expand_path('one', 'a')}], cookbook.paths
  end

  def test_add_project_dir_loads_cookbook_file_for_mappings_if_it_exists
    prepare 'cookbook.yml', 'type: one'
    cookbook = Cookbook.new
    cookbook.add method_dir, 'cookbook.yml'
    assert_equal [{:type => path('one')}], cookbook.paths
  end

  def test_add_project_dir_pushes_expanded_dir_onto_path_if_cookbook_file_does_not_exist
    cookbook = Cookbook.new
    cookbook.add method_dir, 'cookbook.yml'
    assert_equal [method_dir], cookbook.paths
  end

  #
  # rm test
  #

  def test_rm_deletes_expanded_dir_from_path
    cookbook = Cookbook.new path('a'), File.expand_path('b'), path('c')
    cookbook.rm 'b'
    assert_equal [path('a'), path('c')], cookbook.paths
  end

  def test_rm_expands_mappings_and_removes_the_result_from_path
    cookbook = Cookbook.new :type => File.expand_path('one', 'a')
    cookbook.rm 'a', :type => 'one'
    assert_equal [], cookbook.paths
  end

  #
  # path test
  #

  def test_path_returns_the_effective_path_for_a_type
    cookbook = Cookbook.new path('a'), [method_dir, {:type => 'b'}], {:type => path('c')}
    assert_equal [path('a/type'), path('b'), path('c')], cookbook.path(:type)
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

  def test_find_searches_path_for_the_file
    b = prepare('b/type/file')
    assert_equal b, cookbook.find(:type, 'file')
  end

  def test_find_returns_the_first_existing_file
    a = prepare('a/type/file')
    b = prepare('b/type/file')
    assert_equal a, cookbook.find(:type, 'file')
  end

  def test_find_checks_each_extname_if_no_file_is_found
    a = prepare('a/type/file.txt')
    b = prepare('a/type/script.rb')
    assert_equal a, cookbook.find(:type, 'file', ['.txt', '.rb'])
    assert_equal b, cookbook.find(:type, 'script', ['.txt', '.rb'])
  end

  def test_find_checks_each_extname_before_checking_other_paths
    a = prepare('a/type/file.txt')
    b = prepare('b/type/file')
    assert_equal a, cookbook.find(:type, 'file', ['.txt'])
  end

  def test_find_returns_nil_if_no_file_is_found
    assert_equal nil, cookbook.find(:type, 'file')
  end
end