require File.expand_path('../../test_helper', __FILE__)
require 'linecook/utils'

# Test Constants
module ConstName
end

module ConstantNest
  module ConstName
  end
end

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

  #
  # constantize test
  #

  def test_constantize_returns_the_existing_constant
    # ::ConstName
    assert_equal ConstName, constantize("ConstName")
    assert_equal ConstName, constantize("::ConstName")
    assert_equal ConstName, constantize("Object::ConstName")

    # ConstantNest::ConstName
    assert_equal ConstantNest::ConstName, constantize("ConstantNest::ConstName")
    assert_equal ConstantNest::ConstName, constantize("::ConstantNest::ConstName")
    assert_equal ConstantNest::ConstName, constantize("Object::ConstantNest::ConstName")
  end

  def test_constantize_raise_error_for_invalid_constant_names
    assert_raises(NameError) { constantize("") }
    assert_raises(NameError) { constantize("::") }
    assert_raises(NameError) { constantize("const_name") }
  end

  def test_constantize_raises_error_if_constant_does_not_exist
    assert_raises(NameError) { constantize("Non::Existant") }
    assert_raises(NameError) { constantize("::Non::Existant") }
  end

  def test_constantize_yields_current_const_and_missing_constant_names_to_the_block
    was_in_block = false
    constantize("Non::Existant") do |const, const_names|
      assert_equal Object, const
      assert_equal ["Non", "Existant"], const_names
      was_in_block = true
    end
    assert was_in_block

    was_in_block = false
    constantize("ConstName::Non::Existant") do |const, const_names|
      assert_equal ConstName, const
      assert_equal ["Non", "Existant"], const_names
      was_in_block = true
    end
    assert was_in_block
  end

  def test_constantize_returns_return_value_of_block_when_yielding_to_the_block
    assert_equal(ConstName, constantize("ConstName") { false })
    assert_equal(false, constantize("Non::Existant") { false })
  end
end