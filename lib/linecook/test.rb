module Linecook
  module Test
    module ClassMethods
      attr_accessor :class_dir
      
      # Infers the test directory from the calling file.
      #   'some_class_test.rb' => 'some_class_test'
      def self.extended(base)
        calling_file = caller[2].gsub(/:\d+(:in .*)?$/, "")
        base.class_dir = calling_file.chomp(File.extname(calling_file))
      end
    end
    
    module ModuleMethods
      module_function
      
      def included(base)
        base.extend base.kind_of?(Class) ? ClassMethods : ModuleMethods
        super
      end
    end
    
    extend ModuleMethods
    
    attr_reader :user_dir
    attr_reader :method_dir
    
    def setup
      super
      @user_dir   = Dir.pwd
      @method_dir = File.expand_path(method_name, self.class.class_dir)
      
      cleanup method_dir
      FileUtils.mkdir_p method_dir
      Dir.chdir method_dir
    end
    
    def teardown
      Dir.chdir user_dir
      
      unless ENV["KEEP_OUTPUTS"] == "true"
        cleanup self.class.class_dir
      end
      
      super
    end
    
    def cleanup(dir)
      FileUtils.rm_r(dir) if File.exists?(dir)
    end
    
    def path(relative_path)
      File.expand_path(relative_path, method_dir)
    end
    
    def file(relative_path, &block)
      target = path(relative_path)
      target_dir = File.dirname(target)
      
      FileUtils.mkdir_p(target_dir) unless File.exists?(target_dir)
      block ? File.open(target, 'w', &block) : FileUtils.touch(target)
      
      target
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
