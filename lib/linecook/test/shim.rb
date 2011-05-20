require 'test/unit'

if Object.const_defined?(:MiniTest)
  # MiniTest renames method_name as name.  For backwards compatibility it must
  # be added back.
  class MiniTest::Unit::TestCase
    def method_name
      __name__
    end
  end
end
