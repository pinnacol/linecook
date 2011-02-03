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
  
  def test_nest_hashes_auto_nest
    hash = Attributes.nest_hash
    hash[:a] = 1
    hash[:b][:c] = 2
    
    assert_equal({
      :a => 1,
      :b => {:c => 2}
    }, hash)
  end
  
  #
  # Attributes.disable_nest_hash test
  #
  
  def test_disable_nest_hash_returns_a_copy_of_hash_with_auto_nesting_turned_off
    hash = Attributes.nest_hash
    hash[:a] = 1
    hash[:b][:c] = 2
    
    assert_equal({
      :a => 1,
      :b => {:c => 2}
    }, hash)
    
    hash = Attributes.disable_nest_hash(hash)
    
    assert_equal({
      :a => 1,
      :b => {:c => 2}
    }, hash)
    
    assert_equal(nil, hash[:c])
    assert_equal(nil, hash[:b][:d])
  end
  
  def test_disable_nest_hash_does_not_disable_the_orignal_hash
    original = Attributes.nest_hash
    disabled = Attributes.disable_nest_hash(original)
    
    assert_equal({},  original[:a])
    assert_equal(nil, disabled[:a])
  end
  
  def test_disable_nest_hash_returns_a_deep_copy
    original = Attributes.nest_hash
    original[:a] = {:b => 1}
    
    disabled = Attributes.disable_nest_hash(original)
    
    original[:b] = 1
    disabled[:b] = 2
    disabled[:a][:b] = 2
    
    assert_equal(1, original[:b])
    assert_equal(2, disabled[:b])
    
    assert_equal(1, original[:a][:b])
    assert_equal(2, disabled[:a][:b])
  end
  
  #
  # documentation test
  #
  
  def test_attributes_documentation
    attributes = Attributes.new
    attributes.instance_eval %{
      attrs['a'] = 'A'
      attrs['b']['c'] = 'C'
    }
    
    expected = {'a' => 'A', 'b' => {'c' => 'C'}}
    assert_equal expected, attributes.to_hash
  end
  
  #
  # attrs test
  #
  
  def test_attrs_auto_fills_to_allow_setting_of_nested_hash_values
    attrs = attributes.attrs
    attrs[:a] = 1
    attrs[:b][:c] = 2
    
    assert_equal({
      :a => 1,
      :b => {:c => 2}
    }, attrs)
    
    assert_equal({}, attrs[:c])
    assert_equal({}, attrs[:b][:d])
  end
  
  def test_attrs_is_not_indifferent
    attrs = attributes.attrs
    attrs[:a] = 1
    attrs['a'] = 2
    
    assert_equal({
      :a => 1,
      'a' => 2
    }, attrs)
  end
  
  #
  # to_hash test
  #
  
  def test_to_hash_returns_attrs_with_auto_nesting_turned_off
    attrs = attributes.attrs
    attrs[:a] = 1
    attrs[:b][:c] = 2
    
    hash = attributes.to_hash
    assert_equal({
      :a => 1,
      :b => {:c => 2}
    }, hash)
    
    assert_equal nil, hash[:c]
    assert_equal nil, hash[:b][:d]
  end
  
  def test_to_hash_does_not_break_attrs
    attrs = attributes.attrs
    
    attrs[:a] = 1
    assert_equal({
      :a => 1
    }, attributes.to_hash)
    
    attrs[:b][:c] = 2
    assert_equal({
      :a => 1,
      :b => {:c => 2}
    },  attributes.to_hash)
  end
end
