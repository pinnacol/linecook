require File.expand_path('../../test_helper', __FILE__)
require 'linecook/test'

class RecipeTest < Test::Unit::TestCase
  include Linecook::Test
  
  Package = Linecook::Package
  Recipe = Linecook::Recipe
  
  attr_accessor :package, :recipe
  
  def setup
    super
    @package = Package.new
    @recipe  = package.setup_recipe
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
    package = Package.new
    recipe  = package.setup_recipe
    
    recipe.extend Helper
    recipe.instance_eval do
      echo 'a', 'b c'
      echo 'X Y'.downcase, :z
    end
    
    expected = %{
echo 'a b c'
echo 'x y z'
}
    assert_equal expected, "\n" + recipe.result
  end
  
  #
  # _target_name_ test
  #
  
  def test__target_name__is_the_name_of_target_in_package
    assert_equal 'file', recipe._target_name_
    assert_equal recipe._target_.path, package.source_path('file')
  end
  
  #
  # target_name test
  #
  
  def test_target_name_is_an_alias_for__target_name_
    assert_equal recipe._target_name_, recipe.target_name
  end
  
  #
  # _target_ test
  #
  
  def test__target__allows_direct_writing
    recipe._target_ << 'str'
    assert_equal 'str', recipe.result
  end
  
  #
  # target test
  #
  
  def test_target_is_an_alias_for_target_
    assert_equal recipe._target_.object_id, recipe.target.object_id
  end
  
  #
  # close test
  #
  
  def test_close_closes__target_
    assert_equal false, recipe._target_.closed?
    recipe.close
    assert_equal true, recipe._target_.closed?
  end
  
  #
  # closed? test
  #
  
  def test_closed_check_returns_true_if__target__is_closed
    assert_equal false, recipe.closed?
    recipe._target_.close
    assert_equal true, recipe.closed?
  end
  
  #
  # result test
  #
  
  def test_result_returns_current_target_content
    recipe.write 'abc'
    assert_equal 'abc', recipe.result
    
    recipe.capture_block do
      recipe.write 'xyz'
      assert_equal 'xyz', recipe.result
    end
    
    assert_equal 'abc', recipe.result
  end
  
  def test_result_allows_further_modification
    recipe.write 'abc'
    
    assert_equal 'abc', recipe.result
    assert_equal 'abc', recipe.result
    
    recipe.write 'xyz'
    
    assert_equal 'abcxyz', recipe.result
  end
  
  def test_result_always_returns__target__content_when_closed
    recipe.write 'abc'
    recipe.close
    
    assert_equal 'abc', recipe.result
    
    recipe.capture_block do
      recipe.write 'xyz'
      assert_equal 'abc', recipe.result
    end
    
    assert_equal 'abc', recipe.result
  end

  #
  # attributes test
  #

  def test_attributes_evals_the_attributes_file_in_the_context_of_attributes
    path = prepare('example.rb') {|io| io << "attrs[:key] = 'value'"}
    package.manifest['attributes'] = {'name' => path}
    
    assert_equal nil, recipe.attrs[:key]
    
    recipe.attributes('name')
    assert_equal 'value', recipe.attrs[:key]
  end
  
  def test_attributes_evals_a_block_for_attrs
    assert_equal nil, recipe.attrs[:key]
    
    recipe.attributes do
      attrs[:key] = 'value'
    end
    
    assert_equal 'value', recipe.attrs[:key]
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
  # helpers test
  #
  
  def test_helpers_requires_helper_and_extends_self_with_helper_module
    prepare('lib/recipe_test/require_helper.rb') {|io| io << %q{
      class RecipeTest
        module RequireHelper
          def help; end
        end
      end
    }}
    
    lib_dir = path('lib')
    begin
      $:.unshift lib_dir
      
      assert_equal false, recipe.respond_to?(:help)
      recipe.helpers "recipe_test/require_helper"
      assert_equal true, recipe.respond_to?(:help)
    ensure
      $:.delete lib_dir
    end
  end

  #
  # file_path test
  #

  def test_file_path_registers_file_from_files_dir
    path = prepare('example.txt') {|io| io << 'content'}
    package.manifest['files'] = {'source' => path}
    
    assert_equal '${0%/file}/target', recipe.file_path('source', 'target')
    assert_equal 'content', package.content('target')
  end
  
  #
  # recipe_path test
  #

  def test_recipe_path_evals_the_recipe_file_in_the_context_of_a_new_recipe
    path = prepare('example.rb') {|io| io << "target << 'content'"}
    package.manifest['recipes'] = {'source' => path}
    
    assert_equal '${0%/file}/target', recipe.recipe_path('source', 'target')
    
    assert_equal "", package.content(recipe.target_name)
    assert_equal "content", package.content('target')
  end
  
  #
  # template_path test
  #

  def test_template_path_templates_and_registers_file_from_templates_dir
    path = prepare('example.erb') {|io| io << "got <%= key %>" }
    package.manifest['templates'] = {'source' => path}
    
    locals = {:key => 'value'}
    assert_equal '${0%/file}/target', recipe.template_path('source', 'target', 0600, locals)
    
    assert_equal 'got value', package.content('target')
  end
  
  def test_template_path_adds_attrs_to_locals
    path = prepare('example.erb') {|io| io << "got <%= attrs['key'] %><%= key %>" }
    package.manifest['templates'] = {'source' => path}
    
    recipe.attrs['key'] = 'val'
    recipe.template_path('source', 'target', 0600, :key => 'ue')
    
    assert_equal 'got value', package.content('target')
  end
  
  def test_template_path_respects_attrs_manually_added_to_locals
    path = prepare('example.erb') {|io| io << "got <%= attrs['key'] %>" }
    package.manifest['templates'] = {'source' => path}
    
    recipe.attrs['key'] = 'ignored'
    recipe.template_path('source', 'target', 0600, :attrs => {'key' => 'value'})
    
    assert_equal 'got value', package.content('target')
  end
  
  #
  # capture_path test
  #
  
  def test_capture_path_creates_file_from_recipe_block
    setup_recipe do
      capture_path('target') { write 'content'}
    end
    recipe.close
    
    assert_equal 'content', package.content('target')
  end
  
  def test_nested_capture_path_produces_new_recipe_context_each_time
    setup_recipe do
      capture_path('a') do 
        write 'A'
        capture_path('b') do 
          write 'B'
        end
      end
    end
    recipe.close
    
    assert_equal 'A', package.content('a')
    assert_equal 'B', package.content('b')
  end
  
  def test_capture_path_updates_target_name_for_block_but_not__target_name_
    setup_recipe 'recipe' do
      writeln "#{target_name}:#{_target_name_}"
      capture_path('target') do
        writeln "#{target_name}:#{_target_name_}"
      end
      writeln "#{target_name}:#{_target_name_}"
    end
    recipe.close
    
    assert_equal "recipe:recipe\nrecipe:recipe\n", package.content('recipe')
    assert_equal "target:recipe\n", package.content('target')
  end
  
  #
  # write test
  #
  
  def test_write_writes_to_current_target
    str = nil
    setup_recipe do
      write 'a'
      str = capture_block { write 'b'}
      write 'c'
    end
    
    assert_equal "ac", recipe.result
    assert_equal "b", str
  end
  
  #
  # writeln test
  #
  
  def test_writeln_puts_to_current_target
    str = nil
    setup_recipe do
      writeln 'a'
      str = capture_block { writeln 'b'}
      writeln 'c'
    end
    
    assert_equal "a\nc\n", recipe.result
    assert_equal "b\n", str
  end
  
  #
  # rewrite test
  #
  
  def test_rewrite_truncates_results_at_first_match_of_pattern_and_returns_match
    setup_recipe do
      write 'abcabcabc'
      match = rewrite(/ca/)
      write '.'
      write match[0].upcase
    end
    
    assert_equal "ab.CA", recipe.result
  end
  
  def test_rewrite_returns_nil_for_non_matching_pattern
    setup_recipe do
      write 'abc'
      match = rewrite(/xyz/)
      write '.'
      write match.inspect
    end
    
    assert_equal "abc.nil", recipe.result
  end
  
  def test_rewrite_yield_match_to_block_and_returns_block_result
    setup_recipe do
      write 'abcabcabc'
      write rewrite(/ca/) {|match| match[0].upcase }
    end
    
    assert_equal "abCA", recipe.result
  end
  
  #
  # capture_block test
  #
  
  def test_capture_block_updates_target_for_block_but_not__target_
    setup_recipe do
      target <<  'a'
      _target_ << 'A'
      capture_block do
        target << 'b'
        _target_ << 'B'
      end
      target << 'c'
      _target_ << 'C'
    end
    
    assert_equal "aABcC", recipe.result
  end
  
  def test_close_during_capture_block_closes__target__not_target
    assert_equal false, recipe.closed?
    
    recipe.capture_block do 
      assert_equal false, recipe.target.closed?
      recipe.close
      assert_equal false, recipe.target.closed?
    end
    
    assert_equal true, recipe.closed?
  end
  
  #
  # rstrip test
  #
  
  def test_rstrip_rstrips_target_and_returns_stripped_whitespace
    recipe.write " a b \n \t\r\n "
    assert_equal " \n \t\r\n ", recipe.rstrip
    assert_equal " a b", recipe.result
  end
  
  def test_rstrip_returns_empty_string_if_no_whitespace_is_available_to_be_stripped
    recipe.write "a b"
    assert_equal "", recipe.rstrip
    assert_equal "a b", recipe.result
  end
  
  def test_rstrip_removes_all_whitespace_up_to_start
    recipe.write "  \n "
    assert_equal "  \n ", recipe.rstrip
    assert_equal "", recipe.result
  end
  
  def test_rstrip_removes_lots_of_whitespace
    recipe.write "a b"
    recipe.write " " * 10
    recipe.write "\t" * 10
    recipe.write "\n" * 10
    recipe.write " " * 10
    
    expected = (" " * 10) + ("\t" * 10) + ("\n" * 10) + (" " * 10)
    assert_equal expected, recipe.rstrip
    assert_equal "a b", recipe.result
  end
  
  #
  # indent test
  #

  def test_indent_documentation
    setup_recipe do
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
}, "\n" + recipe.result
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
  # write_callback test
  #
  
  def test_write_callback_writes_callback
    package.callbacks['cb'].puts 'content'
    
    assert_recipe %{
      content
    } do
      write_callback 'cb'
    end
  end
  
  def test_write_callback_may_be_used_multiple_times
    package.callbacks['cb'].puts 'content'
    
    assert_recipe %{
      content
      content
    } do
      write_callback 'cb'
      write_callback 'cb'
    end
  end
  
  #
  # callback test
  #
  
  def test_callback_captures_block_to_named_callback
    assert_recipe %{
      acebd
    } do
      write 'a'
      callback 'cb' do
        write 'b'
      end
      write 'c'
      callback 'cb' do
        writeln 'd'
      end
      write 'e'
      write_callback 'cb'
    end
  end
end
