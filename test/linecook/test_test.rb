require File.expand_path('../../test_helper', __FILE__)
require 'linecook/test'

class LinecookTestTest < Test::Unit::TestCase
  include Linecook::Test
  
  def cookbook_dir
    method_dir
  end
  
  #
  # setup_package test
  #
  
  def test_setup_package_and_package_testing
    prepare('recipes/example.rb') {|io| io << "target << Array.new(attrs['n'], 'success').join(',')"}
    
    setup_package 'linecook' => {'recipes' => 'example'}, 'n' => 3
    package.build
    
    assert_equal "success,success,success", package.content('example')
  end
  
  # #
  # # script_test
  # #
  # 
  # def test_script_test_passes_if_script_exits_zero
  #   script_test "exit 0"
  # end
  # 
  # def test_script_test_fails_if_script_exits_non_zero
  #   assert_raises(Test::Unit::AssertionFailedError) { script_test "exit 1" }
  # end
  # 
  # def test_script_test_builds_package_and_runs_script_from_package_dir
  #   script_test %q{
  #     if [ "$(sh recipe)" = "hello world" ]; then exit 0; fi
  #     exit 1
  #   } do
  #     target.puts 'echo hello world'
  #   end
  # end
  # 
  # def test_script_test_resets_package
  #   script_test %q{
  #     if [ "$(sh recipe)" = "hello world" ]; then exit 0; fi
  #     exit 1
  #   } do
  #     target.puts 'echo hello world'
  #   end
  #   
  #   script_test %q{
  #     if [ "$(sh recipe)" = "goodnight moon" ]; then exit 0; fi
  #     exit 1
  #   } do
  #     target.puts 'echo goodnight moon'
  #   end
  # end
  
  #
  # vbox_test test
  #
  
  def test_end_to_end
    build_remote do
      target.puts 'echo hello world'
      target.puts 'echo hello world'
    end
    
    assert_remote_script %Q{
      % bash packages/recipe | tee one
      hello world
      hello world
      % cat one
      hello world
      hello world
    } 
  end
  
  def test_end_to_end_two
    build_remote do
      target.puts 'echo goonight moon'
    end
    
    assert_remote_script %Q{
      % bash packages/recipe
      goonight moon
    }
    
    assert_raises(Test::Unit::AssertionFailedError) do
      assert_remote_script %Q{
        % bash packages/recipe
        goonight m0on
      }
    end
    
    assert_remote_script %Q{
      % bash packages/recipe
      goonight moon
    }
  end
end