require File.expand_path('../../test_helper', __FILE__)
require 'line_cook/cookbook'

class CookbookTest < Test::Unit::TestCase
  include LineCook::TestHelper
  Cookbook = LineCook::Cookbook
  
  attr_reader :cookbook
  
  def setup
    super
    @cookbook = Cookbook.new current_dir
  end
  
  #
  # AGET test
  #
  
  def test_AGET_returns_attributes_files_with_rb_extname
    a = prepare('attributes/a.rb')
    b = prepare('attributes/b/b.rb')
    c = prepare('attributes/c.yml')
    d = prepare('tmp/d.rb')
    
    assert_equal({
      'attributes/a.rb' => a,
      'attributes/b/b.rb' => b
    }, cookbook[:attributes])
  end
  
  def test_AGET_returns_all_files
    a = prepare('files/a.txt')
    b = prepare('files/b/b.rb')
    c = prepare('files/c.yml')
    d = prepare('tmp/d.txt')
    
    assert_equal({
      'files/a.txt' => a,
      'files/b/b.rb' => b,
      'files/c.yml' => c
    }, cookbook[:files])
  end
  
  def test_AGET_returns_nested_helper_definitions_with_erb_extname
    a = prepare('helpers/a/a.erb')
    b = prepare('helpers/b/b/b.erb')
    c = prepare('helpers/c.erb')
    d = prepare('helpers/d.rb')
    e = prepare('tmp/e/e.erb')
    
    assert_equal({
      'helpers/a/a.erb' => a,
      'helpers/b/b/b.erb' => b
    }, cookbook[:definitions])
  end
  
  def test_AGET_returns_helpers_with_rb_extname
    a = prepare('helpers/a.rb')
    b = prepare('helpers/b/b.rb')
    c = prepare('helpers/c.erb')
    d = prepare('tmp/d.rb')
    
    assert_equal({
      'helpers/a.rb' => a,
      'helpers/b/b.rb' => b
    }, cookbook[:helpers])
  end
  
  def test_AGET_returns_recipes_with_rb_extname
    a = prepare('recipes/a.rb')
    b = prepare('recipes/b/b.rb')
    c = prepare('recipes/c.txt')
    d = prepare('tmp/d.rb')
    
    assert_equal({
      'recipes/a.rb' => a,
      'recipes/b/b.rb' => b,
    }, cookbook[:recipes])
  end
  
  def test_AGET_returns_non_nested_scripts_with_yml_extname
    a = prepare('scripts/a.yml')
    b = prepare('scripts/b/b.yml')
    c = prepare('scripts/c.txt')
    d = prepare('tmp/d.yml')
    
    assert_equal({
      'scripts/a.yml' => a
    }, cookbook[:scripts])
  end
  
  def test_AGET_returns_templates_with_erb_extname
    a = prepare('templates/a.erb')
    b = prepare('templates/b/b.erb')
    c = prepare('templates/c.txt')
    d = prepare('tmp/d.erb')
    
    assert_equal({
      'templates/a.erb' => a,
      'templates/b/b.erb' => b,
    }, cookbook[:templates])
  end
  
  #
  # manifest test
  #
  
  def test_manifest_merges_files_for_MANIFEST_TYPES
    a = prepare('attributes/a.rb')
    b = prepare('files/b.txt')
    c = prepare('helpers/c/c.erb')
    d = prepare('helpers/d.rb')
    e = prepare('recipes/e.rb')
    f = prepare('scripts/f.yml')
    g = prepare('templates/g.erb')
    
    assert_equal({
      'attributes/a.rb' => a,
      'files/b.txt'     => b,
      'helpers/d.rb'    => d,
      'recipes/e.rb'    => e,
      'scripts/f.yml'   => f,
      'templates/g.erb' => g
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
    
    cookbook = Cookbook.new(dir1, dir2)
    
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
    
    cookbook = Cookbook.new(dir1, dir2)
    
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
end