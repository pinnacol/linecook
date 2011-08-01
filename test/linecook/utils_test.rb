require File.expand_path('../../test_helper', __FILE__)
require 'linecook/utils'

class UtilsTest < Test::Unit::TestCase
  include Linecook::Utils
  
  #
  # deep_merge test
  #
  
  def test_deep_merge_performs_deep_merge_of_two_hashes
    a = {:a => 0, :b => 0, :c => {:x => 0, :y => 0}}
    b = {:b => 1, :c => {:y => 1, :z => 1}, :d => 1}
    
    expected = {:a => 0, :b => 1, :c => {:x => 0, :y => 1, :z => 1}, :d => 1}
    assert_equal expected, deep_merge(a, b)
  end
end