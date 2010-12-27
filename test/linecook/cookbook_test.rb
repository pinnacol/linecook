require File.expand_path('../../test_helper', __FILE__)
require 'linecook/cookbook'

class CookbookTest < Test::Unit::TestCase
  include Linecook::TestHelper
  Cookbook = Linecook::Cookbook
  
  DIR_ONE = File.expand_path('../../fixtures/dir_one', __FILE__)
  DIR_TWO = File.expand_path('../../fixtures/dir_two', __FILE__)
  
  MANIFEST = {
    'files/a.txt' => File.join(DIR_ONE, 'files/a.txt'),
    'files/b.txt' => File.join(DIR_TWO, 'files/b.txt'),
    'files/c.txt' => File.join(DIR_TWO, 'files/c.txt')
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
  
  def manifest(config)
    config['gems'] ||= []  # prevent assesment of default gems
    cookbook = Cookbook.new(current_dir, config)
    cookbook.extend MockSpecs
    cookbook.manifest
  end
  
  def test_manifest_returns_manifest_of_matching_files_along_paths
    assert_equal MANIFEST, manifest(
      'paths' => [DIR_ONE, DIR_TWO]
    )
  end
  
  def test_manifest_splits_paths
    assert_equal MANIFEST, manifest(
      'paths' => "#{DIR_ONE}:#{DIR_TWO}"
    )
  end
  
  def test_manifest_resolves_paths_from_gems
    assert_equal MANIFEST, manifest(
      'gems' => ['one', 'two']
    )
  end
  
  def test_manifest_splits_gems
    assert_equal MANIFEST, manifest(
      'gems' => 'one:two'
    )
  end
  
  def test_manifest_searches_gems_then_paths
    assert_equal MANIFEST, manifest(
      'paths' => [DIR_TWO],
      'gems'  => ['one']
    )
  end
  
  def test_manifest_overrides_results_with_config_manifest
    assert_equal MANIFEST, manifest(
      'paths'    => [DIR_ONE],
      'manifest' => {
        'files/b.txt' => File.join(DIR_TWO, 'files/b.txt'),
        'files/c.txt' => File.join(DIR_TWO, 'files/c.txt')
      }
    )
  end
end