require 'linecook/test/regexp_escape'

module Linecook
  module Test
    module ShellTest
      DEFAULT_PS1 = '% '
      DEFAULT_PS2 = '> '
      
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
      
      def parse(str, options={})
        if options[:outdent]
          str = outdent_str(str)
        else
          str.lstrip!
        end
        
        ps1 = options[:ps1] || DEFAULT_PS1
        ps1_length = ps1.length
        
        ps2 = options[:ps2] || DEFAULT_PS2
        ps2_length = ps2.length
        
        commands = []
        command, output = nil, nil
        str.each_line do |line|
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
      
      def sh(cmd, options={})
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
        puts "  (#{elapsed}s) #{verbose? ? cmd : original_cmd}" unless quiet?
        result
      end
      
      # Peforms a shell test.  Shell tests execute the command and yield the
      # $stdout result to the block for validation.  The command is executed
      # through sh, ie using IO.popen.
      #
      # Options provided to sh_test are merged with the sh_test_options set
      # for the class.
      #
      # ==== Command Aliases
      #
      # The options allow specification of a command pattern that gets
      # replaced with a command alias.  Only the first instance of the command
      # pattern is replaced.  In addition, shell tests allow the expected result
      # to be specified inline with the command.  Used together, these allow
      # multiple tests of a complex command to be specified easily:
      #
      #   opts = {
      #     :cmd_pattern => '% argv_inspect',
      #     :cmd => 'ruby -e "puts ARGV.inspect"'
      #   }
      #
      #   sh_test %Q{
      #   % argv_inspect goodnight moon
      #   ["goodnight", "moon"]
      #   }, opts
      #
      #   sh_test %Q{
      #   % argv_inspect hello world
      #   ["hello", "world"]
      #   }, opts
      #
      # ==== Indents
      #
      # To improve the readability of tests, sh_test will lstrip each line in the
      # expected output to the same degree as the command line.  So for instance
      # these all pass:
      #
      #   sh_test %Q{
      #   % argv_inspect hello world
      #   ["hello", "world"]
      #   }, opts
      #
      #   sh_test %Q{
      #       % argv_inspect hello world
      #       ["hello", "world"]
      #   }, opts
      #
      #       sh_test %Q{
      #       % argv_inspect hello world
      #       ["hello", "world"]
      #       }, opts
      #
      # Turn off indent stripping by specifying :indent => false.
      #
      # ==== ENV variables
      #
      # Options may specify a hash of env variables that will be set in the
      # subprocess.
      #
      #   sh_test %Q{
      #   ruby -e "puts ENV['SAMPLE']"
      #   value
      #   }, :env => {'SAMPLE' => 'value'}
      #
      # Note it is better to specify env variables in this way rather than
      # through the command trick 'VAR=value cmd ...', as that syntax does
      # not work on Windows.  As a point of interest, see
      # http://gist.github.com/107363 for a demonstration of ENV
      # variables being inherited by subprocesses.
      # 
      def sh_test(commands, options={})
        options = sh_test_options.merge(options)
        
        unless commands.kind_of?(Array)
          commands = parse(commands, options)
        end
        
        commands.each do |cmd, output, status|
          result = sh(cmd, options)
          
          assert_equal(output, result, cmd) if output
          assert_equal(status, $?.to_i, cmd) if status
        end
      end
      
      # Similar to sh_test, but matches the output against each of the
      # regexps.  A hash of sh options can be provided as the last argument;
      # it will be merged with the default sh_test_options.
      #
      # The output is yielded to the block, if given, for further validation.
      # Returns the sh output.
      def sh_match(commands, options={})
        options = sh_test_options.merge(options)
        
        unless commands.kind_of?(Array)
          commands = parse(commands, options)
        end
        
        commands.each do |cmd, output, status|
          result = sh(cmd, options)
          
          if output
            if output.kind_of?(String)
              output = RegexpEscape.new(output)
            end
            
            assert_alike(output, result, cmd)
          end
          
          assert_equal(status, $?.to_i, cmd) if status
        end
      end
      
      # Returns a hash of default sh_test options.
      def sh_test_options
        {
          :ps1 => DEFAULT_PS1,
          :ps2 => DEFAULT_PS2,
          :prefix => '0<&- 2>&1 ',
          :suffix => '',
          :outdent => true,
          :env => {},
          :replace_env => false
        }
      end

      # Asserts whether or not the a and b strings are equal, with a more
      # readable output than assert_equal for large strings (especially large
      # strings with significant whitespace).  Note that assert_output_equal
      # lstrips indentation off of 'a', so that these all pass:
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
      def assert_output_equal(a, b, msg=nil)
        a = outdent_str(a)
        
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
      def assert_alike(a, b, msg=nil)
        if a.kind_of?(String)
          a = RegexpEscape.new(outdent_str(a))
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

      private

      # helper for stripping indentation off a string
      def outdent_str(str) # :nodoc:
        str =~ /\A(?:\s*?\n)( *)(.*)\z/m ? $2.gsub!(/^ {0,#{$1.length}}/, '') : str
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
end