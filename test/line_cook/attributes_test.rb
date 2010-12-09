require File.expand_path('../../test_helper', __FILE__)
require 'line_cook/attributes'

class AttributesTest < Test::Unit::TestCase
  Attributes = LineCook::Attributes
  
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
  # attrs test
  #
  
  def test_attrs_merges_default_normal_override_and_user_attrs
    attributes.default[:a]    = 'A'
    attributes.default[:b]    = '-'
    attributes.default[:c]    = '-'
    attributes.default[:d]    = '-'
    
    attributes.normal[:b]     = 'B'
    attributes.normal[:c]     = '-'
    attributes.normal[:d]     = '-'
    
    attributes.override[:c]   = 'C'
    attributes.override[:d]   = '-'
    
    attributes.user_attrs[:d] = 'D'
    
    assert_equal({
      :a => 'A',
      :b => 'B',
      :c => 'C',
      :d => 'D'
    }, attributes.attrs)
  end
  
  def test_attrs_performs_deep_merge
    attributes.default[:a] = 'A'
    attributes.default[:b] = '-'
    attributes.default[:one][:a] = 'a'
    attributes.default[:one][:b] = '-'
    
    attributes.user_attrs[:b] = 'B'
    attributes.user_attrs[:one] = {:b => 'b'}
    
    assert_equal({
      :a => 'A',
      :b => 'B',
      :one => {
        :a => 'a',
        :b => 'b'
      }
    }, attributes.attrs)
  end
  
  def test_attrs_are_cached
    assert_equal attributes.attrs.object_id, attributes.attrs.object_id
  end
  
  def test_attrs_are_recalculated_if_specified
    assert attributes.attrs.object_id != attributes.attrs(true).object_id
  end
  
  #
  # reset test
  #
  
  def test_reset_clears_default_normal_and_override_attrs
    attributes.default[:a] = 'A'
    attributes.normal[:b] = 'B'
    attributes.override[:c] = 'C'
    attributes.user_attrs[:d] = 'D'
    
    assert_equal({
      :a => 'A',
      :b => 'B',
      :c => 'C',
      :d => 'D'
    }, attributes.attrs)
    
    attributes.reset
    
    assert_equal({
      :d => 'D'
    }, attributes.attrs)
  end
end
