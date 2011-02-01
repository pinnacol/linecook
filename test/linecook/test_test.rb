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
  
  #
  # vbox_test test
  #
  
  def test_end_to_end
    build_package do
      target.puts 'echo hello world'
      target.puts 'echo hello world'
    end
    
    check_package %Q{
      % bash package/recipe | tee one
      hello world
      hello world
      % cat one
      hello world
      hello world
    } 
  end
  
  def test_end_to_end_two
    build_package do
      target.puts 'echo goonight moon'
    end
    
    check_package %Q{
      % bash package/recipe
      goonight moon
    }
    
    assert_raises(Test::Unit::AssertionFailedError) do
      check_package %Q{
        % bash package/recipe
        goonight m0on
      }
    end
    
    check_package %Q{
      % bash package/recipe
      goonight moon
    }
  end
end