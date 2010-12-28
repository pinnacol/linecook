require 'linecook/cookbook'
require 'linecook/recipe'
require 'linecook/test/file_test'
require 'linecook/test/regexp_escape'

module Linecook
  module Test
    include FileTest
    
    def cookbook
      @cookbook ||= Linecook::Cookbook.init(user_dir)
    end
    
    def recipe
      @recipe ||= Linecook::Recipe.new('recipe', cookbook.manifest)
    end
    
    def assert_recipe(expected, &block)
      recipe.instance_eval(&block)
      assert_output_equal expected, recipe.result
    end

    def assert_content(expected, name)
      recipe.close

      source_path = recipe.registry.invert[name]
      assert_output_equal expected, File.read(source_path)
    end
    
    # Asserts whether or not the a and b strings are equal, with a more
    # readable output than assert_equal for large strings (especially large
    # strings with significant whitespace).
    #
    # One gotcha is that assert_output_equal lstrips indentation off of 'a',
    # so that these all pass:
    #
    #   assert_output_equal %q{
    #   line one
    #   line two
    #   }, "line one\nline two\n"
    #
    #   assert_output_equal %q{
    #     line one
    #     line two
    #   }, "line one\nline two\n
    #
    #     assert_output_equal %q{
    #     line one
    #     line two
    #     }, "line one\nline two\n"
    #
    # Use the assert_output_equal! method to prevent indentation stripping.
    def assert_output_equal(a, b, msg=nil)
      a = strip_indent(a)
      assert_output_equal!(a, b, msg)
    end

    # Same as assert_output_equal but without indentation stripping.
    def assert_output_equal!(a, b, msg=nil)
      if a == b
        assert true
      else
        flunk %Q{
#{msg}
==================== expected output ====================
#{whitespace_escape(a)}
======================== but was ========================
#{whitespace_escape(b)}
=========================================================
}
      end
    end

    # Asserts whether or not b is like a (which should be a Regexp), and
    # provides a more readable output in the case of a failure as compared
    # with assert_match.
    #
    # If a is a string, then indentation is stripped off and it is turned
    # into a RegexpEscape. Using that syntax, all these pass:
    #
    #   assert_alike %q{
    #   the time is: :...:
    #   now!
    #   }, "the time is: #{Time.now}\nnow!\n"
    #
    #   assert_alike %q{
    #     the time is: :...:
    #     now!
    #   }, "the time is: #{Time.now}\nnow!\n"
    #
    #     assert_alike %q{
    #     the time is: :...:
    #     now!
    #     }, "the time is: #{Time.now}\nnow!\n"
    #
    # Use assert_alike! to prevent indentation stripping (conversion to a
    # RegexpEscape is still in effect).
    def assert_alike(a, b, msg=nil)
      a = strip_indent(a) if a.kind_of?(String)
      assert_alike!(a, b, msg)
    end

    # Same as assert_alike but without indentation stripping.
    def assert_alike!(a, b, msg=nil)
      a = RegexpEscape.new(a) if a.kind_of?(String)

      if b =~ a
        assert true
      else
        flunk %Q{
#{msg}
================= expected output like ==================
#{whitespace_escape(a)}
======================== but was ========================
#{whitespace_escape(b)}
=========================================================
}
      end
    end

    private

    # helper for stripping indentation off a string
    def strip_indent(str) # :nodoc:
      if str =~ /\A\s*?\n( *)(.*)\z/m
        indent, str = $1, $2, $3

        if indent.length > 0
          str.gsub!(/^ {0,#{indent.length}}/, '')
        end
      end

      str
    end

    # helper for formatting escaping whitespace into readable text
    def whitespace_escape(str) # :nodoc:
      str.to_s.gsub(/\s/) do |match|
        case match
        when "\n" then "\\n\n"
        when "\t" then "\\t"
        when "\r" then "\\r"
        when "\f" then "\\f"
        else match
        end
      end
    end
  end
end