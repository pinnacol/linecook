require File.expand_path('../../test_helper', __FILE__)
require 'linecook/attributes'

class AttributesTest < Test::Unit::TestCase
  Attributes = Linecook::Attributes
  
  attr_reader :attributes
  
  def setup
    super
    @attributes = Attributes.new
  end
  
  #
  # Attributes.nest_hash test
  #
  
  def test_nest_hash_auto_fills_to_allow_setting_of_nested_hash_values
    hash = Attributes.nest_hash
    hash[:a] = 1
    hash[:b][:c] = 2
    
    assert_equal({
      :a => 1,
      :b => {:c => 2}
    }, hash)
  end
  
  #
  # current test
  #
  
  def test_current_merges_attrs_and_user_attrs
    attributes.attrs[:a]    = 'A'
    attributes.attrs[:b]    = '-'
    
    attributes.user_attrs[:b] = 'B'
    
    assert_equal({
      :a => 'A',
      :b => 'B'
    }, attributes.current)
  end
  
  def test_current_performs_deep_merge
    attributes.attrs[:a] = 'A'
    attributes.attrs[:b] = '-'
    attributes.attrs[:one][:a] = 'a'
    attributes.attrs[:one][:b] = '-'
    
    attributes.user_attrs[:b] = 'B'
    attributes.user_attrs[:one] = {:b => 'b'}
    
    assert_equal({
      :a => 'A',
      :b => 'B',
      :one => {
        :a => 'a',
        :b => 'b'
      }
    }, attributes.current)
  end
  
  def test_current_attrs_are_cached
    assert_equal attributes.current.object_id, attributes.current.object_id
  end
  
  #
  # reset test
  #
  
  def test_reset_clears_attrs
    attributes.attrs[:a] = 'A'
    attributes.user_attrs[:b] = 'B'
    
    assert_equal({
      :a => 'A',
      :b => 'B'
    }, attributes.current)
    
    attributes.reset
    
    assert_equal({
      :b => 'B'
    }, attributes.current)
  end
end
