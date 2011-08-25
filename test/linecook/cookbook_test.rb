require File.expand_path('../../test_helper', __FILE__)
require 'linecook/cookbook'

class CookbookTest < Test::Unit::TestCase
  include ShellTest::FileMethods
  include FileMethodsShim

  Cookbook = Linecook::Cookbook

  attr_accessor :cookbook

  def setup
    super
    @current = Cookbook.default_path_map
    Cookbook.default_path_map = {:type => ['one', 'two']}
    @cookbook = Cookbook.new path('a'), path('b')
  end

  def teardown
    Cookbook.default_path_map = @current
    super
  end

  #
  # initialize test
  #

  def test_initialize_adds_path_map_to_registry
    cookbook = Cookbook.new({:type => path('a')})
    assert_equal({:type => [path('a')]}, cookbook.registry)
  end

  def test_initialize_expands_path_map_relative_to_dir_if_specified
    cookbook = Cookbook.new [method_dir, {:type => 'a'}]
    assert_equal({:type => [path('a')]}, cookbook.registry)
  end

  def test_initialize_expands_paths_with_default_path_map
    cookbook = Cookbook.new path('a'), path('b')
    assert_equal({
      :type => [path('a/one'), path('a/two'), path('b/one'), path('b/two')]
    }, cookbook.registry)
  end

  #
  # add test
  #

  def test_add_expands_default_map_relative_to_dir_and_pushes_results_onto_registry
    cookbook = Cookbook.new
    cookbook.add 'a'
    cookbook.add 'b'
    assert_equal({
      :type => [File.expand_path('a/one'), File.expand_path('a/two'), File.expand_path('b/one'), File.expand_path('b/two')]
    }, cookbook.registry)
  end

  def test_add_expands_path_map_and_adds_the_result_to_registry
    cookbook = Cookbook.new
    cookbook.add 'a', :type => 'one'
    cookbook.add 'b', :type => 'two'
    assert_equal({
      :type => [File.expand_path('a/one'), File.expand_path('b/two')]
    }, cookbook.registry)
  end

  def test_add_project_dir_loads_cookbook_file_for_path_map_if_it_exists
    prepare 'cookbook_file.yml', %{
      type: one
    }
    cookbook = Cookbook.new
    cookbook.add method_dir, 'cookbook_file.yml'
    assert_equal({
      :type => [path('one')]
    }, cookbook.registry)
  end

  def test_add_project_detects_default_file_name_if_it_exists
    prepare 'cookbook.yml', %{
      type: one
    }
    cookbook = Cookbook.new
    cookbook.add method_dir
    assert_equal({
      :type => [path('one')]
    }, cookbook.registry)
  end

  def test_add_project_uses_default_path_map_if_cookbook_file_does_not_exist
    cookbook = Cookbook.new
    cookbook.add method_dir, 'cookbook.yml'
    assert_equal({
      :type => [path('one'), path('two')]
    }, cookbook.registry)
  end

  #
  # rm test
  #

  def test_rm_expands_default_map_relative_to_dir_and_deletes_results_from_registry
    cookbook = Cookbook.new path('a'), path('b')
    cookbook.rm path('b')
    assert_equal({
      :type => [path('a/one'), path('a/two')]
    }, cookbook.registry)
  end

  def test_rm_expands_path_map_and_removes_the_results_from_registry
    cookbook = Cookbook.new path('a'), path('b')
    cookbook.rm path('a'), :type => 'two'
    cookbook.rm path('b'), :type => 'one'
    assert_equal({
      :type => [path('a/one'), path('b/two')]
    }, cookbook.registry)
  end

  #
  # path test
  #

  def test_path_returns_the_effective_path_for_a_type
    cookbook = Cookbook.new path('a'), path('b')
    assert_equal [path('a/one'), path('a/two'), path('b/one'), path('b/two')], cookbook.path(:type)
  end

  #
  # _find_ test
  #

  def test__find__returns_nil_for_non_existing_absolute_paths
    path = File.expand_path('file')
    assert_equal false, File.exists?(path)
    assert_equal nil, cookbook._find_(:type, path)
  end

  def test__find__returns_nil_if_no_file_is_found
    assert_equal nil, cookbook._find_(:type, 'file')
  end

  def test__find__only_checks_extnames_if_source_name_has_no_extname
    a = prepare('a/one/file.txt.rb')
    assert_equal nil, cookbook._find_(:type, 'file.txt', ['.rb'])
  end

  def test__find__returns_nil_for_nil_type_or_filename
    assert_equal nil, cookbook._find_(nil, 'file')
    assert_equal nil, cookbook._find_(:type, nil)
  end

  #
  # find test
  #

  def test_find_returns_existing_absolute_paths
    path = prepare('file', '')
    assert_equal path, File.expand_path(path)
    assert_equal path, cookbook.find(:type, path)
  end

  def test__find__raises_error_for_non_existant_absolute_paths
    path = File.expand_path('file')
    assert_equal false, File.exists?(path)
    err = assert_raises(RuntimeError) { cookbook.find(:type, path) }
    assert_equal "no such file: #{path.inspect}", err.message
  end

  def test_find_searches_path_for_the_file
    b = prepare('b/one/file')
    assert_equal b, cookbook.find(:type, 'file')
  end

  def test_find_returns_the_first_existing_file
    a = prepare('a/one/file')
    b = prepare('b/one/file')
    assert_equal a, cookbook.find(:type, 'file')
  end

  def test_find_checks_each_extname_if_no_file_is_found
    a = prepare('a/one/file.txt')
    b = prepare('a/one/script.rb')
    assert_equal a, cookbook.find(:type, 'file', ['.txt', '.rb'])
    assert_equal b, cookbook.find(:type, 'script', ['.txt', '.rb'])
  end

  def test_find_checks_each_extname_before_checking_other_paths
    a = prepare('a/one/file.txt')
    b = prepare('b/one/file')
    assert_equal a, cookbook.find(:type, 'file', ['.txt'])
  end

  def test_find_raises_error_if_no_file_is_found
    err = assert_raises(RuntimeError) { cookbook.find(:type, 'file', ['.txt', '.rb']) }
    assert_equal 'could not find file: "file" (tried .txt, .rb)', err.message
  end

  def test_find_error_reflects_not_trying_extnames_on_files_with_an_extname
    err = assert_raises(RuntimeError) { cookbook.find(:type, 'file.txt', ['.rb']) }
    assert_equal 'could not find file: "file.txt"', err.message
  end

  def test_find_error_reflects_nil_type
    err = assert_raises(RuntimeError) { cookbook.find(nil, 'file.txt', ['.rb']) }
    assert_equal 'could not find file: "file.txt" (nil type specified)', err.message
  end

  def test_find_error_reflects_nil_filename
    err = assert_raises(RuntimeError) { cookbook.find(:type, nil, ['.rb']) }
    assert_equal 'could not find file: nil', err.message
  end
end