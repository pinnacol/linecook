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

  def test_disable_nest_hash_turns_off_auto_nesting_of_each_nest_hash
    hash = Attributes.nest_hash
    hash[:a] = 1
    hash[:b][:c] = 2

    assert_equal({
      :a => 1,
      :b => {:c => 2}
    }, hash)

    Attributes.disable_nest_hash(hash)

    assert_equal({
      :a => 1,
      :b => {:c => 2}
    }, hash)

    assert_equal(nil, hash[:c])
    assert_equal(nil, hash[:b][:d])
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

  def test_to_hash_permanently_disables_auto_nesting_of_attrs
    attrs = attributes.attrs
    assert_equal({}, attrs[:a])

    attributes.to_hash
    assert_equal(nil, attrs[:b])
  end
end
