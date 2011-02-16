require File.expand_path('../../../test_helper', __FILE__)
require 'linecook/test/file_test'

class FileTestTest < Test::Unit::TestCase
  include Linecook::Test::FileTest
  
  #
  # class_dir test
  #
  
  def test_include_guesses_class_dir_as_file_name_minus_extname
    assert_equal __FILE__.chomp(File.extname(__FILE__)), class_dir
  end
  
  def test_class_dir_can_be_set_at_the_class_level
    path = prepare('file_test_parent_class.rb') do |io|
      io.puts %q{
        class FileTestAssignClassDir
          include Linecook::Test::FileTest
          self.class_dir = 'custom'
        end
      }
    end
    require path
    
    assert_equal 'custom', FileTestAssignClassDir.class_dir
  end
  
  def test_subclass_guesses_class_dir_as_file_name_minus_extname
    path = prepare('file_test_parent_class.rb') do |io|
      io.puts %q{
        class FileTestParentClass
          include Linecook::Test::FileTest
        end
      }
    end
    require path
    
    path = prepare('file_test_child_class.rb') do |io|
      io.puts %q{
        class FileTestChildClass < FileTestParentClass
        end
      }
    end
    require path
    
    assert_equal path('file_test_child_class'), FileTestChildClass.class_dir
  end
  
  def test_submodule_guesses_class_dir_as_file_name_minus_extname
    path = prepare('file_test_submodule.rb') do |io|
      io.puts %q{
        module FileTestSubmodule
          include Linecook::Test::FileTest
        end
      }
    end
    require path
    
    path = prepare('file_test_include_submodule.rb') do |io|
      io.puts %q{
        class FileTestIncludeSubmodule
          include FileTestSubmodule
        end
      }
    end
    require path
    
    assert_equal path('file_test_include_submodule'), FileTestIncludeSubmodule.class_dir
  end
  
  #
  # method_dir test
  #
  
  def test_method_dir_is_method_name_under_the_class_dir
    expected = File.expand_path('test_method_dir_is_method_name_under_the_class_dir', class_dir)
    assert_equal expected, method_dir
  end
  
  #
  # path test
  #
  
  def test_path_returns_relative_path_expanded_to_method_dir
    assert_equal File.expand_path('relative/path', method_dir), path('relative/path')
  end
  
  def test_path_raises_error_resulting_path_is_not_relative_to_method_dir
    err = assert_raises(RuntimeError) { path('../not_relative') }
    assert_equal 'does not make a path relative to method_dir: "../not_relative"', err.message
  end
  
  #
  # prepare test
  #
  
  def test_prepare_makes_a_file_and_all_parent_directories
    path = prepare('dir/file') {}
    assert_equal true, File.exists?(path)
  end
  
  #
  # cleanup test
  #
  
  def test_cleanup_removes_method_dir_and_all_contents
    prepare('dir/file') {}
    cleanup
    assert_equal false, File.exists?(method_dir)
  end
  
  no_cleanup
  def test_no_cleanup_turns_off_cleanup_one
    prepare('dir/file') {}
    
    cleanup
    assert_equal true, File.exists?(method_dir)
    
    remove method_dir
  end
  
  cleanup :test_cleanup_may_be_turned_on_for_a_specific_method
  def test_cleanup_may_be_turned_on_for_a_specific_method
    prepare('dir/file') {}
    
    cleanup
    assert_equal false, File.exists?(method_dir)
  end
  
  def test_no_cleanup_turns_off_cleanup_two
    prepare('dir/file') {}
    
    cleanup
    assert_equal true, File.exists?(method_dir)
    
    remove method_dir
  end
  
  cleanup
  def test_cleanup_turns_on_cleanup_one
    prepare('dir/file') {}
    
    cleanup
    assert_equal false, File.exists?(method_dir)
  end
  
  no_cleanup :test_cleanup_may_be_turned_off_for_a_specific_method
  def test_cleanup_may_be_turned_off_for_a_specific_method
    prepare('dir/file') {}
    
    cleanup
    assert_equal true, File.exists?(method_dir)
    
    remove method_dir
  end
  
  def test_cleanup_turns_on_cleanup_two
    prepare('dir/file') {}
    
    cleanup
    assert_equal false, File.exists?(method_dir)
  end
  
  cleanup_paths 'a', 'b'
  def test_cleanup_paths_defines_the_relative_paths_to_cleanup
    prepare('a/x') {}
    prepare('a/y') {}
    prepare('b') {}
    prepare('c') {}
    
    cleanup
    
    assert_equal false, File.exists?(path('a'))
    assert_equal false, File.exists?(path('b'))
    assert_equal true, File.exists?(path('c'))
    
    remove method_dir
  end
  
  def test_cleanup_paths_persists_until_next_cleanup_paths_one
    prepare('b') {}
    prepare('c') {}
    
    cleanup
    
    assert_equal false, File.exists?(path('b'))
    assert_equal true, File.exists?(path('c'))
    
    remove method_dir
  end
  
  cleanup_paths '.'
  def test_cleanup_paths_persists_until_next_cleanup_paths_two
    prepare('b') {}
    prepare('c') {}
    
    cleanup
    
    assert_equal false, File.exists?(method_dir)
  end
end
