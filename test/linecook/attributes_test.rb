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
  # documentation test
  #
  
  def test_attributes_documentation
    user_env = {'a' => 'A'}
    attributes = Attributes.new(user_env)
    attributes.instance_eval %{
      attrs['a'] = '-'
      attrs['b'] = 'B'
    }
  
    expected = {'a' => 'A', 'b' => 'B'}
    assert_equal expected, attributes.current

    attributes = Attributes.new
    attributes.instance_eval %{
      attrs[:a]       = :A
      attrs['a']['b'] = 'B'
    }
    
    expected = {:a => :A, 'a' => {'b' => 'B'}}
    assert_equal expected, attributes.current
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
  end
  
  #
  # current test
  #
  
  def test_current_merges_attrs_and_env
    attributes.attrs[:a] = 'A'
    attributes.attrs[:b] = '-'
    
    attributes.env[:b]   = 'B'
    
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
    
    attributes.env[:b]   = 'B'
    attributes.env[:one] = {:b => 'b'}
    
    assert_equal({
      :a => 'A',
      :b => 'B',
      :one => {
        :a => 'a',
        :b => 'b'
      }
    }, attributes.current)
  end
end
