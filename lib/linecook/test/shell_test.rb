require 'linecook/test/regexp_escape'
require 'linecook/test/command_parser'
require 'linecook/test/shim'

module Linecook
  module Test
    module ShellTest
      
      def setup
        super
        @notify_method_name = true
      end

      # Returns true if the ENV variable 'VERBOSE' is true.  When verbose,
      # ShellTest prints the expanded commands of sh_test to $stdout.
      def verbose?
        verbose = ENV['VERBOSE']
        verbose && verbose =~ /^true$/i ? true : false
      end
      
      # Sets the specified ENV variables and returns the *current* env.
      # If replace is true, current ENV variables are replaced; otherwise
      # the new env variables are simply added to the existing set.
      def set_env(env={}, replace=false)
        current_env = {}
        ENV.each_pair do |key, value|
          current_env[key] = value
        end

        ENV.clear if replace

        env.each_pair do |key, value|
          if value.nil?
            ENV.delete(key)
          else
            ENV[key] = value
          end
        end if env

        current_env
      end

      # Sets the specified ENV variables for the duration of the block.
      # If replace is true, current ENV variables are replaced; otherwise
      # the new env variables are simply added to the existing set.
      #
      # Returns the block return.
      def with_env(env={}, replace=false)
        current_env = nil
        begin
          current_env = set_env(env, replace)
          yield
        ensure
          if current_env
            set_env(current_env, true)
          end
        end
      end
      
      def sh(cmd)
        if @notify_method_name && verbose?
          @notify_method_name = false
          puts
          puts method_name 
        end
        
        start  = Time.now
        result = `#{cmd}`
        finish = Time.now
        
        if verbose?
          elapsed = "%.3f" % [finish-start]
          puts "  (#{elapsed}s) #{cmd}"
        end
        
        result
      end
      
      def assert_script(script, options={})
        _assert_script outdent(script), options
      end
      
      def _assert_script(script, options={})
        commands = CommandParser.new(options).parse(script)
        commands.each do |cmd, output, status|
          result = sh(cmd)
          
          _assert_output_equal(output, result, cmd) if output
          assert_equal(status, $?.exitstatus, cmd)  if status
        end
      end
      
      def assert_script_match(script, options={})
        _assert_script_match outdent(script), options
      end
      
      def _assert_script_match(script, options={})
        commands = CommandParser.new(options).parse(script)
        commands.each do |cmd, output, status|
          result = sh(cmd)
          
          _assert_alike(output, result, cmd)       if output
          assert_equal(status, $?.exitstatus, cmd) if status
        end
      end
      
      # Asserts whether or not the a and b strings are equal, with a more
      # readable output than assert_equal for large strings (especially large
      # strings with significant whitespace).
      def assert_output_equal(a, b, msg=nil)
        _assert_output_equal outdent(a), b, msg
      end
      
      def _assert_output_equal(a, b, msg=nil)
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
      # If a is a string it is turned into a RegexpEscape.
      def assert_alike(a, b, msg=nil)
        a = outdent(a) if a.kind_of?(String)
        _assert_alike a, b, msg
      end
      
      def _assert_alike(a, b, msg=nil)
        if a.kind_of?(String)
          a = RegexpEscape.new(a)
        end

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
      
      # helper for stripping indentation off a string
      def outdent(str)
        str =~ /\A(?:\s*?\n)( *)(.*)\z/m ? $2.gsub!(/^ {0,#{$1.length}}/, '') : str
      end
      
      # helper for formatting escaping whitespace into readable text
      def whitespace_escape(str)
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
end