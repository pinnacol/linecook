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

  def package
    recipe._package_
  end

  def cookbook
    recipe._cookbook_
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
  # target test
  #

  def test_target_is_an_alias_for__target__
    assert_equal recipe._target_, recipe.target
  end

  #
  # attributes test
  #

  def test_attributes_evals_the_attributes_file_in_the_context_of_attributes
    path = prepare('example.rb') {|io| io << "attrs[:key] = 'value'"}
    assert_equal nil, recipe.attrs[:key]

    recipe.attributes(path)
    assert_equal 'value', recipe.attrs[:key]
  end

  def test_attributes_evals_a_block_for_attrs
    assert_equal nil, recipe.attrs[:key]

    recipe.attributes do
      attrs[:key] = 'value'
    end

    assert_equal 'value', recipe.attrs[:key]
  end

  def test_attributes_loads_yml_files_as_yaml
    path = prepare('example.yml') {|io| io << ":key: value" }
    assert_equal nil, recipe.attrs[:key]

    recipe.attributes(path)
    assert_equal 'value', recipe.attrs[:key]
  end

  def test_attributes_looks_for_files_along_attributes_path
    prepare('attributes/example.yml') {|io| io << ":key: value" }
    cookbook.add(method_dir)

    recipe.attributes('example.yml')
    assert_equal 'value', recipe.attrs[:key]
  end

  def test_attributes_checks_rb_and_yaml_formats
    prepare 'attributes/a.rb', 'attrs[:one] = "A"'
    prepare 'attributes/b.yml', ':two: B'
    cookbook.add(method_dir)

    recipe.attributes('a')
    recipe.attributes('b')
    assert_equal 'A', recipe.attrs[:one]
    assert_equal 'B', recipe.attrs[:two]
  end

  #
  # attrs test
  #

  def test_attrs_merges_attrs_and_env_where_env_wins
    package.env[:a] = 'A'

    recipe.attributes do
      attrs[:a]     = '-'
      attrs[:b]     = 'B'
    end

    assert_equal 'A', recipe.attrs[:a]
    assert_equal 'B', recipe.attrs[:b]
  end

  def test_attrs_are_additive_and_still_ensure_env_wins
    package.env[:a] = 'A'

    recipe.attributes do
      attrs[:a]     = '-'
      attrs[:b]     = '-'
      attrs[:c]     = 'C'
    end

    recipe.attributes do
      attrs[:b]     = 'B'
    end

    assert_equal 'A', recipe.attrs[:a]
    assert_equal 'B', recipe.attrs[:b]
    assert_equal 'C', recipe.attrs[:c]
  end

  def test_attrs_performs_deep_merge
    recipe.attributes do
      attrs[:a] = 'A'
      attrs[:b] = '-'
      attrs[:one][:a] = 'a'
      attrs[:one][:b] = '-'
    end

    package.env[:b]   = 'B'
    package.env[:one] = {:b => 'b'}

    assert_equal 'A', recipe.attrs[:a]
    assert_equal 'B', recipe.attrs[:b]
    assert_equal({:a => 'a', :b => 'b'}, recipe.attrs[:one])
  end

  def test_attrs_does_not_auto_nest
    recipe.attributes { attrs[:b] }

    assert_equal nil, recipe.attrs[:a]
    assert_equal nil, recipe.attrs[:b][:c]
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
end