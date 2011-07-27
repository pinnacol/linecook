require File.expand_path('../../test_helper', __FILE__)
require 'linecook/recipe'

class RecipeTest < Test::Unit::TestCase
  include ShellTest

  Recipe = Linecook::Recipe

  # Note these methods largely duplicate what is in Linecook::Test but I
  # prefer to repeat them to keep Recipe tests separate from the Test module
  # tests, which depend on Recipe, and thereby prevent a circular test setup.

  def recipe
    @recipe ||= Recipe.new
  end

  def setup_recipe(&block)
    @recipe = Recipe.new
    @recipe.instance_eval(&block) if block
    @recipe
  end

  def assert_recipe(expected, &block)
    setup_recipe(&block)
    assert_equal outdent(expected), recipe._result_
  end

  #
  # documentation test
  #

  module Helper
    # This is an ERB template compiled to write to a Recipe.
    #
    #   compiler = ERB::Compiler.new('<>')
    #   compiler.put_cmd = "write"
    #   compiler.insert_cmd = "write"
    #   compiler.compile("echo '<%= args.join(' ') %>'\n")
    #
    def echo(*args)
      write "echo '"; write(( args.join(' ') ).to_s); write "'\n"
    end
  end

  def test_recipe_documentation
    recipe  = Recipe.new do
      extend Helper
      echo 'a', 'b c'
      echo 'X Y'.downcase, :z
    end

    expected = %{
echo 'a b c'
echo 'x y z'
}
    assert_equal expected, "\n" + recipe._result_
  end

  #
  # initialize test
  #

  def test_initialize_sets_default__target__
    assert recipe._target_.respond_to?(:write)
  end

  #
  # _capture_ test
  #

  def test__capture__updates_target_for_block_but_not__target_
    setup_recipe do
      target <<  'a'
      _target_ << 'A'
      _capture_ do
        target << 'b'
        _target_ << 'B'
      end
      target << 'c'
      _target_ << 'C'
    end

    assert_equal "aABcC", recipe._result_
  end

  #
  # _result_ test
  #

  def test__result__returns__target__content
    recipe._target_.puts 'content'
    assert_equal "content\n", recipe._result_
  end

  def test__result__allows_further_modification
    recipe.write 'abc'

    assert_equal 'abc', recipe._result_
    assert_equal 'abc', recipe._result_

    recipe.write 'xyz'

    assert_equal 'abcxyz', recipe._result_
  end

  #
  # _rewrite_ test
  #

  def test__rewrite__truncates_results_at_first_match_of_pattern_and_returns_match
    setup_recipe do
      write 'abcabcabc'
      match = _rewrite_(/ca/)
      write '.'
      write match[0].upcase
    end

    assert_equal "ab.CA", recipe._result_
  end

  def test__rewrite__returns_nil_for_non_matching_pattern
    setup_recipe do
      write 'abc'
      match = _rewrite_(/xyz/)
      write '.'
      write match.inspect
    end

    assert_equal "abc.nil", recipe._result_
  end

  def test__rewrite__yield_match_to_block_and_returns_block_result
    setup_recipe do
      write 'abcabcabc'
      write _rewrite_(/ca/) {|match| match[0].upcase }
    end

    assert_equal "abCA", recipe._result_
  end

  #
  # _rstrip_ test
  #

  def test__rstrip___rstrip_s_target_and_returns_stripped_whitespace
    recipe.write " a b \n \t\r\n "
    assert_equal " \n \t\r\n ", recipe._rstrip_
    assert_equal " a b", recipe._result_
  end

  def test__rstrip__returns_empty_string_if_no_whitespace_is_available_to_be_stripped
    recipe.write "a b"
    assert_equal "", recipe._rstrip_
    assert_equal "a b", recipe._result_
  end

  def test__rstrip__removes_all_whitespace_up_to_start
    recipe.write "  \n "
    assert_equal "  \n ", recipe._rstrip_
    assert_equal "", recipe._result_
  end

  def test__rstrip__removes_lots_of_whitespace
    whitespace = (" " * 10) + ("\t" * 10) + ("\n" * 10) + (" " * 10)
    recipe.write "a b"
    recipe.write whitespace

    assert_equal whitespace, recipe._rstrip_
    assert_equal "a b", recipe._result_
  end

  #
  # target test
  #

  def test_target_is_an_alias_for__target__
    assert_equal recipe._target_, recipe.target
  end

  #
  # helper test
  #

  def test_helper_requires_helper_and_extends_with_module
    prepare 'lib/helper_module.rb', %{
      module HelperModule
        def helper_method
        end
      end
    }

    lib_path = path 'lib'
    begin
      $:.unshift lib_path
      recipe.helper 'helper_module'
    ensure
      $:.delete lib_path
    end

    assert recipe.respond_to?(:helper_method)
  end

  #
  # capture test
  #

  def test_capture_captures_block_and_returns_output
    recipe.write 'a'
    str = recipe.capture { recipe.write 'b' }
    recipe.write str.upcase
    recipe.write 'c'

    assert_equal "aBc", recipe._result_
  end

  #
  # write test
  #

  def test_write_writes_to_target
    recipe.write 'content'
    assert_equal 'content', recipe._result_
  end

  #
  # writeln test
  #

  def test_writeln_writes_to_target
    recipe.writeln 'content'
    assert_equal "content\n", recipe._result_
  end

  #
  # indent test
  #

  def test_indent_documentation
    recipe = Recipe.new do
      writeln 'a'
      indent do
        writeln 'b'
        outdent do
          writeln 'c'
          indent do
            writeln 'd'
          end
          writeln 'c'
        end
        writeln 'b'
      end
      writeln 'a'
    end

    assert_equal %q{
a
  b
c
  d
c
  b
a
}, "\n" + recipe._result_
  end

  def test_indent_indents_target_output_during_block
    assert_recipe %q{
      a
        b
        b
      a
    } do
      writeln 'a'
      indent do
        writeln 'b'
        writeln 'b'
      end
      writeln 'a'
    end
  end

  def test_indent_allows_specification_of_indent
    assert_recipe %q{
      a
      .b
      .b
      a
    } do
      writeln 'a'
      indent('.') do
        writeln 'b'
        writeln 'b'
      end
      writeln 'a'
    end
  end

  def test_indents_may_be_nested
    assert_recipe %q{
      a
        b
          c
          c
        b
      a
    } do
      writeln 'a'
      indent do
        writeln 'b'
        indent do
          writeln 'c'
          writeln 'c'
        end
        writeln 'b'
      end
      writeln 'a'
    end
  end

  #
  # outdent test
  #

  def test_outdent_does_nothing_outside_of_indent
    assert_recipe %q{
      a
       b
        c
    } do
      outdent do
        writeln 'a'
        writeln ' b'
        writeln '  c'
      end
    end
  end

  def test_outdent_strips_the_current_indentation_off_of_a_section
    assert_recipe %q{
      a
      +b
      c
      -x
      --y
      z
      z
      --y
      -x
      c
      +b
      a
    } do
      writeln 'a'
      indent('+') do
        writeln 'b'
        outdent do
          writeln 'c'
          indent('-') do
            writeln 'x'
            indent('-') do
              writeln 'y'
              outdent do
                writeln 'z'
                writeln 'z'
              end
              writeln 'y'
            end
            writeln 'x'
          end
          writeln 'c'
        end
        writeln 'b'
      end
      writeln 'a'
    end
  end
end