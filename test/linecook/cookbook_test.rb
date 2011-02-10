require File.expand_path('../../test_helper', __FILE__)
require 'linecook/cookbook'
require 'linecook/test/file_test'

class CookbookTest < Test::Unit::TestCase
  include Linecook::Test::FileTest
  Cookbook = Linecook::Cookbook
  
  DIR_ONE = File.expand_path('../../fixtures/dir_one', __FILE__)
  DIR_TWO = File.expand_path('../../fixtures/dir_two', __FILE__)
  
  MANIFEST = {
    'files' => {
      'a.txt' => File.join(DIR_ONE, 'files/a.txt'),
      'b.txt' => File.join(DIR_TWO, 'files/b.txt'),
      'c.txt' => File.join(DIR_TWO, 'files/c.txt')
    }
  }
  
  #
  # Gem mocks
  #
  
  MockSpec = Struct.new(:full_gem_path)
  
  module MockSpecs
    def latest_specs
      {
        'one' => MockSpec.new(DIR_ONE),
        'two' => MockSpec.new(DIR_TWO)
      }
    end
  end
  
  #
  # manifest test
  #
  
  def test_manifest_returns_manifest_of_matching_files_along_paths
    cookbook = Cookbook.new('paths' => [DIR_ONE, DIR_TWO])
    assert_equal MANIFEST, cookbook.manifest
  end
  
  def test_manifest_splits_paths
    cookbook = Cookbook.new('paths' => "#{DIR_ONE}:#{DIR_TWO}")
    assert_equal MANIFEST, cookbook.manifest
  end
  
  def test_manifest_resolves_paths_from_gems
    cookbook = Cookbook.new('gems' => ['one', 'two'])
    cookbook.extend MockSpecs
    
    assert_equal MANIFEST, cookbook.manifest
  end
  
  def test_manifest_splits_gems
    cookbook = Cookbook.new('gems' => 'one:two')
    cookbook.extend MockSpecs
    
    assert_equal MANIFEST, cookbook.manifest
  end
  
  def test_manifest_searches_gems_then_paths
    cookbook = Cookbook.new('paths' => [DIR_TWO], 'gems'  => ['one'])
    cookbook.extend MockSpecs
    
    assert_equal MANIFEST, cookbook.manifest
  end
  
  def test_manifest_overrides_results_with_config_manifest
    cookbook = Cookbook.new(
      'paths'    => [DIR_ONE],
      'manifest' => {
        'files' => {
          'b.txt' => File.join(DIR_TWO, 'files/b.txt'),
          'c.txt' => File.join(DIR_TWO, 'files/c.txt')
        }
      }
    )
    
    assert_equal MANIFEST, cookbook.manifest
  end
  
  def test_manifest_rewrites_resource_paths
    cookbook = Cookbook.new(
      'rewrite'  => {
        '/post.' => '.',
        'pre/'   => ''
      },
      'manifest' => {
        'files' => {
          'a.txt'      => File.join(DIR_ONE, 'files/a.txt'),
          'b/post.txt' => File.join(DIR_TWO, 'files/b.txt'),
          'pre/c.txt'  => File.join(DIR_TWO, 'files/c.txt')
        }
      }
    )
    
    assert_equal MANIFEST, cookbook.manifest
  end
end