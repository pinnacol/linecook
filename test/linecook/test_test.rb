require File.expand_path('../../test_helper', __FILE__)
require 'linecook/test'

class TestTest < Test::Unit::TestCase
  include Linecook::Test

  TestUnitErrorClass = Object.const_defined?(:MiniTest) ? MiniTest::Assertion : Test::Unit::AssertionFailedError

  #
  # setup_package test
  #

  def test_setup_package_initializes_package_with_env
    package = setup_package 'key' => 'value'
    assert_equal 'value', package.env['key']
  end

  def test_setup_package_sets_package
    setup_package 'key' => 'a'
    assert_equal 'a', package.env['key']

    setup_package 'key' => 'b'
    assert_equal 'b', package.env['key']
  end

  #
  # setup_recipe test
  #

  def test_setup_recipe_sets_recipe
    setup_recipe
    recipe.write 'a'
    assert_equal 'a', recipe._result_

    setup_recipe
    recipe.write 'b'
    assert_equal 'b', recipe._result_
  end

  module HelperModule
    def echo(*args)
      writeln "echo '#{args.join(' ')}'"
    end
  end

  def test_setup_recipe_extends_recipe_with_helpers
    use_helpers HelperModule
    setup_recipe

    recipe.echo 'a', 'b', 'c'
    assert_equal "echo 'a b c'\n", recipe._result_
  end

  #
  # assert_recipe test
  #

  def test_assert_recipe_passes_if_expected_and_actual_content_are_the_same
    assert_recipe %q{
      content
    } do
      writeln "content"
    end
  end

  def test_assert_recipe_passes_if_expected_and_actual_content_differ
    assert_raises(TestUnitErrorClass) do
      assert_recipe %q{
        expected
      } do
        writeln "actual"
      end
    end
  end

  def test_assert_recipe_makes_new_recipe_for_each_call
    assert_recipe('a') { write 'a'}
    assert_recipe('b') { write 'b'}
  end

  def test_assert_recipe_returns_recipe
    recipe = assert_recipe('a') { write 'a'}
    assert_equal 'a', recipe._result_
  end

  def test_assert_recipe_may_specify_recipe_to_check
    recipe = assert_recipe('a') { write 'a'}
    assert_recipe('a', recipe)
  end

  def test_assert_recipe_evaluates_block_for_recipe_if_specified
    recipe = setup_recipe { write 'a'}
    assert_recipe('ab', recipe) { write 'b'}
  end

  def test_assert_recipe_uses_current_package_if_set
    setup_package('key' => 'value')
    assert_recipe('value') { write attrs['key'] }
  end

  #
  # assert_recipe_matches test
  #

  def test_assert_recipe_matches_passes_if_expected_and_actual_contents_match
    assert_recipe_matches %q{
      co:..:nt
    } do
      writeln "content"
    end
  end
end
