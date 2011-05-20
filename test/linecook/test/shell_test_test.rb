require File.expand_path('../../../test_helper', __FILE__)
require 'linecook/test/shell_test'

class ShellTestTest < Test::Unit::TestCase
  include Linecook::Test::ShellTest
  
  TestUnitErrorClass = Object.const_defined?(:MiniTest) ? MiniTest::Assertion : Test::Unit::AssertionFailedError
  
  #
  # set_env test
  #
  
  def test_set_env_sets_the_env_and_returns_the_current_env
    current_env = {}
    begin
      ENV.each_pair do |key, value|
        current_env[key] = value
      end
      
      assert_equal nil, ENV['NEW_ENV_VAR']
      assert_equal nil, current_env['NEW_ENV_VAR']
      
      assert_equal current_env, set_env('NEW_ENV_VAR' => 'value')
      assert_equal 'value', ENV['NEW_ENV_VAR']
    ensure
      ENV.clear
      current_env.each_pair do |key, value|
        ENV[key] = value
      end
    end
  end
  
  #
  # with_env test
  #
  
  def test_with_env_sets_variables_for_duration_of_block
    assert_equal nil, ENV['UNSET_VARIABLE']
    ENV['SET_VARIABLE'] = 'set'
    
    was_in_block = false
    with_env 'UNSET_VARIABLE' => 'unset' do
      was_in_block = true
      assert_equal 'set', ENV['SET_VARIABLE']
      assert_equal 'unset', ENV['UNSET_VARIABLE']
    end
    
    assert_equal true, was_in_block
    assert_equal 'set', ENV['SET_VARIABLE']
    assert_equal nil, ENV['UNSET_VARIABLE']
    assert_equal false, ENV.has_key?('UNSET_VARIABLE')
  end
  
  def test_with_env_resets_variables_even_on_error
    assert_equal nil, ENV['UNSET_VARIABLE']
    
    was_in_block = false
    err = assert_raises(RuntimeError) do
      with_env 'UNSET_VARIABLE' => 'unset' do
        was_in_block = true
        assert_equal 'unset', ENV['UNSET_VARIABLE']
        raise "error"
        flunk "should not have reached here"
      end
    end
    
    assert_equal 'error', err.message
    assert_equal true, was_in_block
    assert_equal nil, ENV['UNSET_VARIABLE']
  end
  
  def test_with_env_replaces_env_if_specified
    ENV['SET_VARIABLE'] = 'set'
    
    was_in_block = false
    with_env({}, true) do
      was_in_block = true
      assert_equal nil, ENV['SET_VARIABLE']
      assert_equal false, ENV.has_key?('SET_VARIABLE')
    end
    
    assert_equal true, was_in_block
    assert_equal 'set', ENV['SET_VARIABLE']
  end
  
  def test_with_env_returns_block_result
    assert_equal "result", with_env {"result"}
  end
  
  def test_with_env_allows_nil_env
    was_in_block = false
    with_env(nil) do
      was_in_block = true
    end
    
    assert_equal true, was_in_block
  end
  
  #
  # verbose test
  #

  def test_verbose_is_true_if_VERBOSE_is_truish
    with_env 'VERBOSE' => 'true' do
      assert_equal true, verbose?
    end

    with_env 'VERBOSE' => 'TruE' do
      assert_equal true, verbose?
    end

    with_env 'VERBOSE' => 'false' do
      assert_equal false, verbose?
    end

    with_env 'VERBOSE' => nil do
      assert_equal false, verbose?
    end
  end

  #
  # assert_script test
  #

  def test_assert_script_correctly_matches_no_output
    assert_script %Q{
ruby -e ""
}

    assert_script %Q{ruby -e ""}
  end

  def test_assert_script_correctly_matches_whitespace_output
    assert_script %Q{
ruby -e 'print "\\t\\n  "'
\t
  }
    assert_script %Q{
echo

}
    assert_script %Q{echo

}
  end

  def test_assert_script_strips_indents
    assert_script %Q{
    echo goodnight
    goodnight
    }

    assert_script %Q{ \t   \r
    echo goodnight
    goodnight
    }

    assert_script %Q{
    ruby -e 'print "\\t\\n  "'
    \t
      }

    assert_script %Q{
    echo

    }

    assert_script %Q{echo

}
  end

  def test_assert_script_fails_on_mismatch
    assert_raises(TestUnitErrorClass) { assert_script %Q{ruby -e ""\nflunk} }
    assert_raises(TestUnitErrorClass) { assert_script %Q{echo pass\nflunk} }
  end
  
  #
  # _assert_script test
  #
  
  def test__assert_script_does_not_strip_indents
    _assert_script %Q{
    ruby -e 'print "    \\t\\n      "'
    \t
      }, :outdent => false
  end
  
  #
  # assert_script_match test
  #

  def test_assert_script_match_matches_regexps_to_output
    assert_script_match %Q{
      % echo "goodnight
      > moon"
      goodnight
      m:.o+.:n
    }
  end
  
  def test_assert_script_match_fails_on_mismatch
    assert_raises(TestUnitErrorClass) do
      assert_script_match %Q{
        % echo 'hello world'
        goodnight m:.o+.:n
      }
    end
  end

  #
  # assert_output_equal test
  #

  def test_assert_output_equal
    assert_output_equal %{
    line one
      line two
    }, "line one\n  line two\n"

    assert_output_equal %{
    line one
      line two}, "line one\n  line two"

    assert_output_equal %{  \t   \r
    line one
    line two
    }, "line one\nline two\n"

    assert_output_equal %{
    
    
    }, "\n\n"

    assert_output_equal %{
    
    }, "\n"

    assert_output_equal %{  \t   \r
    
    }, "\n"

    assert_output_equal %{
    }, ""

    assert_output_equal %q{}, ""
    assert_output_equal %q{line one
line two
}, "line one\nline two\n"
  end

  #
  # assert_alike test
  #

  def test_assert_alike
    assert_alike(/abc/, "...abc...")
  end

  def test_assert_alike_regexp_escapes_strings
    assert_alike "a:...:c", "...alot of random stuff toc..."
  end
end