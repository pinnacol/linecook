require File.expand_path('../../test_helper', __FILE__)
require 'line_cook/cookbook'

class CookbookTest < Test::Unit::TestCase
  include LineCook::TestHelper
  Cookbook = LineCook::Cookbook
  
  attr_reader :cookbook
  
  def setup
    super
    @cookbook = Cookbook.new
  end
  
  #
  # initialize test
  #
  
  def test_initialize_sets_current_dir_into_path_by_default
    assert_equal [current_dir], cookbook.path
  end
  
  def test_initialize_expands_and_sets_path_as_specified
    cookbook = Cookbook.new 'path' => ['/a', 'b']
    assert_equal [File.expand_path('/a'), File.expand_path('b')], cookbook.path
  end
  
  def test_initialize_splits_string_paths_along_colon
    cookbook = Cookbook.new 'path' => '/a:b'
    assert_equal [File.expand_path('/a'), File.expand_path('b')], cookbook.path
  end
  
  #
  # manifest test
  #
  
  def test_manifest_includes_attributes
    a = prepare('attributes/a.rb')
    b = prepare('attributes/b/b.rb')
    c = prepare('attributes/c.yml')
    d = prepare('tmp/d.rb')
    
    assert_equal({
      'attributes/a.rb' => a,
      'attributes/b/b.rb' => b
    }, cookbook.manifest)
  end
  
  def test_manifest_includes_files
    a = prepare('files/a.txt')
    b = prepare('files/b/b.rb')
    c = prepare('files/c.yml')
    d = prepare('tmp/d.txt')
    
    assert_equal({
      'files/a.txt' => a,
      'files/b/b.rb' => b,
      'files/c.yml' => c
    }, cookbook.manifest)
  end
  
  def test_manifest_includes_helpers
    a = prepare('helpers/a/a.erb')
    b = prepare('helpers/b/b/b.erb')
    c = prepare('helpers/c/_c.rb')
    d = prepare('helpers/d/d/_d.rb')
    e = prepare('helpers/e/e.rb')
    f = prepare('helpers/f.erb')
    g = prepare('tmp/g.erb')
    
    assert_equal({
      'helpers/a/a.erb' => a,
      'helpers/b/b/b.erb' => b,
      'helpers/c/_c.rb' => c,
      'helpers/d/d/_d.rb' => d
    }, cookbook.manifest)
  end
  
  def test_manifest_includes_recipes
    a = prepare('recipes/a.rb')
    b = prepare('recipes/b/b.rb')
    c = prepare('recipes/c.txt')
    d = prepare('tmp/d.rb')
    
    assert_equal({
      'recipes/a.rb' => a,
      'recipes/b/b.rb' => b,
    }, cookbook.manifest)
  end
  
  def test_manifest_includes_scripts
    a = prepare('scripts/a.yml')
    b = prepare('scripts/b/b.yml')
    c = prepare('scripts/c.txt')
    d = prepare('tmp/d.yml')
    
    assert_equal({
      'scripts/a.yml' => a
    }, cookbook.manifest)
  end
  
  def test_manifest_includes_templates
    a = prepare('templates/a.erb')
    b = prepare('templates/b/b.erb')
    c = prepare('templates/c.txt')
    d = prepare('tmp/d.erb')
    
    assert_equal({
      'templates/a.erb' => a,
      'templates/b/b.erb' => b,
    }, cookbook.manifest)
  end
  
  #
  # glob test
  #
  
  def test_glob_returns_manifest_of_files_matching_patterns
    a = prepare('a.rb')
    b = prepare('b.rb')
    c = prepare('c.yml')
    
    assert_equal({
      'a.rb' => a,
      'b.rb' => b
    }, cookbook.glob('*.rb'))
  end
  
  def test_glob_searches_for_files_along_each_dir_in_path
    dir1 = tempdir
    dir2 = tempdir
    
    cookbook = Cookbook.new('path' => [dir1, dir2] )
    
    a = prepare('a.rb', dir1)
    b = prepare('b.rb', dir2)
    
    assert_equal({
      'a.rb' => a,
      'b.rb' => b
    }, cookbook.glob('*.rb'))
  end
  
  def test_glob_matches_files_for_leading_dirs_over_tailing_dirs
    dir1 = tempdir
    dir2 = tempdir
    
    cookbook = Cookbook.new('path' => [dir1, dir2])
    
    a1 = prepare('a.rb', dir1)
    b1 = prepare('b.rb', dir1)
    
    b2 = prepare('b.rb', dir2)
    c2 = prepare('c.rb', dir2)
    
    assert_equal({
      'a.rb' => a1,
      'b.rb' => b1,
      'c.rb' => c2
    }, cookbook.glob('*.rb'))
  end
  
  #
  # each_helper test
  #
  
  def test_each_helper_yields_the_sources_and_target_for_each_helper
    a = prepare('helpers/one/a.erb')
    b = prepare('helpers/one/b.erb')
    
    c = prepare('helpers/two/c.erb')
    d = prepare('helpers/two/d.erb')
    
    expected = [
      [[a,b].sort, 'helpers/one.rb'],
      [[c,d].sort, 'helpers/two.rb']
    ]
    
    results = []
    cookbook.each_helper {|sources, target, builder| results << [sources.sort, target] }
    
    expected = expected.sort_by {|(sources, target)| target }
    results = results.sort_by {|(sources, target)| target }
    
    assert_equal expected, results
  end
  
  #
  # each_script test
  #
  
  def test_each_script_yields_the_sources_and_target_for_each_script
    a = prepare('scripts/a.yml')
    b = prepare('scripts/b.yml')
    
    expected = [
      [[a], 'scripts/a'],
      [[b], 'scripts/b']
    ]
    
    results = []
    cookbook.each_script {|sources, target, builder| results << [sources.sort, target] }
    
    expected = expected.sort_by {|(sources, target)| target }
    results = results.sort_by {|(sources, target)| target }
    
    assert_equal expected, results
  end
end