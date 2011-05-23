require 'test/unit'

if Object.const_defined?(:MiniTest)
  # MiniTest renames method_name as name.  For backwards compatibility it must
  # be added back.
  class MiniTest::Unit::TestCase
    class << self
      # Causes a test suite to be skipped.  If a message is given, it will
      # print and notify the user the test suite has been skipped.
      def skip_test(msg=nil)
        @@test_suites.delete(self)
        puts "Skipping #{self}#{msg.empty? ? '' : ': ' + msg}"
      end
    end
    
    def method_name
      __name__
    end
  end
else
  class Test::Unit::TestCase
    class << self
      ################################
      # Test::Unit shims (< ruby 1.9)
      ################################
    
      # Causes a test suite to be skipped.  If a message is given, it will
      # print and notify the user the test suite has been skipped.
      def skip_test(msg=nil)
        @skip_test_suite = true
        skip_messages << msg
      end

      # Modifies the default suite method to skip the suit unless
      # run_test_suite is true.  If the test is skipped, the skip_messages 
      # will be printed along with the default 'Skipping <Test>' message.
      def suite # :nodoc:
        if (@skip_test_suite ||= false)
          skip_message = skip_messages.compact.join(', ')
          puts "Skipping #{name}#{skip_message.empty? ? '' : ': ' + skip_message}"
          # return an empty test suite of the appropriate name
          ::Test::Unit::TestSuite.new(name)
        else
          super
        end
      end

      protected

      def skip_messages # :nodoc:
        @skip_messages ||= []
      end
    end
  end
end
