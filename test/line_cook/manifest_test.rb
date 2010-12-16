require File.expand_path('../../test_helper', __FILE__)
require 'line_cook/manifest'

class ManifestTest < Test::Unit::TestCase
  include LineCook::TestHelper
  Manifest = LineCook::Manifest
  
  attr_reader :manifest
  
  def setup
    super
    @manifest = Manifest.new current_dir
  end
  
  #
  # AGET test
  #
  
  def test_AGET_attributes_returns_manifest_matching_rb_attribute_files
    a = prepare('attributes/a.rb')
    b = prepare('attributes/b/b.rb')
    c = prepare('attributes/c.js')
    d = prepare('tmp/d.rb')
    
    assert_equal({
      'a.rb' => a,
      'b/b.rb' => b
    }, manifest[:attributes])
  end
  
  def test_AGET_files_returns_manifest_matching_all_file_files
    a = prepare('files/a.txt')
    b = prepare('files/b/b.rb')
    c = prepare('files/c.js')
    d = prepare('tmp/d.txt')
    
    assert_equal({
      'a.txt' => a,
      'b/b.rb' => b,
      'c.js' => c
    }, manifest[:files])
  end
  
  def test_AGET_helpers_returns_manifest_matching_erb_files_and_underscore_rb_files
    a = prepare('helpers/a.erb')
    b = prepare('helpers/b/b.erb')
    c = prepare('helpers/_c.rb')
    d = prepare('helpers/d/_d.rb')
    e = prepare('helpers/e.rb')
    f = prepare('tmp/f.erb')
    
    assert_equal({
      'a.erb' => a,
      'b/b.erb' => b,
      '_c.rb' => c,
      'd/_d.rb' => d,
    }, manifest[:helpers])
  end
  
  def test_AGET_recipes_returns_manifest_matching_rb_recipes
    a = prepare('recipes/a.rb')
    b = prepare('recipes/b/b.rb')
    c = prepare('recipes/c.txt')
    d = prepare('tmp/d.rb')
    
    assert_equal({
      'a.rb' => a,
      'b/b.rb' => b,
    }, manifest[:recipes])
  end
  
  def test_AGET_scripts_returns_manifest_of_non_nested_js_scripts
    a = prepare('scripts/a.js')
    b = prepare('scripts/b/b.js')
    c = prepare('scripts/c.txt')
    d = prepare('tmp/d.js')
    
    assert_equal({
      'a.js' => a
    }, manifest[:scripts])
  end
  
  def test_AGET_templates_returns_manifest_matchings_erb_templates
    a = prepare('templates/a.erb')
    b = prepare('templates/b/b.erb')
    c = prepare('templates/c.txt')
    d = prepare('tmp/d.erb')
    
    assert_equal({
      'a.erb' => a,
      'b/b.erb' => b,
    }, manifest[:templates])
  end
  
  #
  # glob test
  #
  
  def test_glob_returns_manifest_of_files_matching_patterns
    a = prepare('type/a.rb')
    b = prepare('type/b.rb')
    c = prepare('type/c.js')
    
    assert_equal({
      'a.rb' => a,
      'b.rb' => b
    }, manifest.glob(:type, '*.rb'))
  end
  
  def test_glob_searches_for_files_along_each_dir
    dir1 = tempdir
    dir2 = tempdir
    
    manifest = Manifest.new(dir1, dir2)
    
    a = prepare('type/a.rb', dir1)
    b = prepare('type/b.rb', dir2)
    
    assert_equal({
      'a.rb' => a,
      'b.rb' => b
    }, manifest.glob(:type, '*.rb'))
  end
  
  def test_glob_matches_files_for_leading_dirs_over_tailing_dirs
    dir1 = tempdir
    dir2 = tempdir
    
    manifest = Manifest.new(dir1, dir2)
    
    a1 = prepare('type/a.rb', dir1)
    b1 = prepare('type/b.rb', dir1)
    
    b2 = prepare('type/b.rb', dir2)
    c2 = prepare('type/c.rb', dir2)
    
    assert_equal({
      'a.rb' => a1,
      'b.rb' => b1,
      'c.rb' => c2
    }, manifest.glob(:type, '*.rb'))
  end
end