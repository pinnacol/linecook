require 'linecook/test/regexp_escape'

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

      # Returns true if the ENV variable 'QUIET' is true or nil.  When quiet,
      # ShellTest does not print any extra information to $stdout.
      #
      # If 'VERBOSE' and 'QUIET' are both set, verbose wins.
      def quiet?
        return false if verbose?

        quiet = ENV['QUIET']
        quiet.nil? || quiet =~ /^true$/i ? true : false
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
      
      def parse_options
        {
          :ps1 => '% ',
          :ps2 => '> ',
          :prefix => '0<&- 2>&1 ',
          :suffix => '',
          :outdent => true
        }
      end
      
      def parse(script, options={})
        options = parse_options.merge(options)
        
        if options[:outdent]
          script = outdent(script)
        else
          script.lstrip!
        end
        
        ps1 = options[:ps1]
        ps1_length = ps1.length
        
        ps2 = options[:ps2]
        ps2_length = ps2.length
        
        commands = []
        command, output = nil, nil
        script.each_line do |line|
          case
          when line.index(ps1) == 0
            commands << [command, output.join, 0] if command
            
            command = line[ps1_length, line.length - ps1_length ]
            output  = []
            
          when command.nil?
            command, output = line, []
          
          when line.index(ps2) == 0
            command << line[ps2_length, line.length - ps2_length]
            
          else
            output << line
          end
        end
        
        commands << [command, output.join, 0] if command
        commands
      end
      
      def sh_options
        {
          :env => {},
          :replace_env => false,
          :prefix => '<&- 2>&1 ',
          :suffix => nil
        }
      end
      
      def sh(cmd, options={})
        options = sh_options.merge(sh_options)
        
        if @notify_method_name && !quiet?
          @notify_method_name = false
          puts
          puts method_name 
        end
        
        start = Time.now
        result = with_env(options[:env], options[:replace_env]) do 
          `#{options[:prefix]}#{cmd}#{options[:suffix]}`
        end
        
        finish = Time.now
        elapsed = "%.3f" % [finish-start]
        puts "  (#{elapsed}s) #{cmd}" unless quiet?
        result
      end
      
      def assert_script(script, options={})
        parse(script, options).each do |cmd, output, status|
          result = sh(cmd, options)
          
          assert_equal(output, result, cmd)  if output
          assert_equal(status, $?.to_i, cmd) if status
        end
      end
      
      def assert_script_match(script, options={})
        parse(script, options).each do |cmd, output, status|
          result = sh(cmd, options)
          
          assert_alike(output, result, cmd)  if output
          assert_equal(status, $?.to_i, cmd) if status
        end
      end
      
      # Asserts whether or not the a and b strings are equal, with a more
      # readable output than assert_equal for large strings (especially large
      # strings with significant whitespace).
      def assert_output_equal(a, b, msg=nil)
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