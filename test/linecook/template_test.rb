require File.expand_path('../../test_helper', __FILE__)
require 'linecook/template'

class TemplateTest < Test::Unit::TestCase
  Template = Linecook::Template
  
  attr_accessor :template
  
  def setup
    @template = Template.new
  end
  
  #
  # documentation test
  #
  
  module Helper
    # This is compiled ERB code, prefixed by 'self.', ie:
    #
    #   "self." + ERB.new("echo '<%= args.join(' ') %>'\n").src
    #
    def echo(*args)
      self._erbout = ''; _erbout.concat "echo '"; _erbout.concat(( args.join(' ') ).to_s); _erbout.concat "'\n"
      _erbout
    end
  end
  
  def test_template_documentation
    template = Template.new.extend Helper
    template.echo 'a', 'b c'
    template.echo 'X Y'.downcase, :z
    
    expected = %{
echo 'a b c'
echo 'x y z'
}
    assert_equal expected, "\n" + template.result
    
    template = Template.new.extend Helper
    template.instance_eval do
      echo 'outer'
      indent do
        echo 'inner'
      end
      echo 'outer'
    end
    
    expected = %{
echo 'outer'
  echo 'inner'
echo 'outer'
}
    assert_equal expected, "\n" + template.result
  end
  
  #
  # result test
  #
  
  def test_result_returns_current_template_results
    template.target << 'abc'
    assert_equal 'abc', template.result
  end
  
  def test_result_does_not_interfere_with_result
    template.target << 'abc'
    
    assert_equal 'abc', template.result
    assert_equal 'abc', template.result
    
    template.target << 'xyz'
    
    assert_equal 'abcxyz', template.result
  end
  
  #
  # rstrip test
  #
  
  def test_rstrip_rstrips_target
    template.target << " a b \n "
    template.rstrip
    assert_equal " a b", template.result
  end
  
  def test_rstrip_removes_all_whitespace_up_to_start
    template.target << "  \n "
    template.rstrip
    assert_equal "", template.result
  end
  
  def test_rstrip_removes_lots_of_whitespace
    template.target << "a b"
    template.target << " " * 100
    template.rstrip
    assert_equal "a b", template.result
  end
end