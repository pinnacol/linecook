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
end