require File.expand_path('../../test_helper', __FILE__)
require 'line_cook/template'

class TemplateTest < Test::Unit::TestCase
  Template = LineCook::Template
  
  attr_accessor :template
  
  def setup
    @template = Template.new
  end
  
  #
  # rstrip test
  #
  
  def test_rstrip_rstrips_erbout
    template.erbout << " a b \n "
    template.rstrip
    assert_equal " a b", template.result
  end
  
  def test_rstrip_removes_all_whitespace_up_to_start
    template.erbout << "  \n "
    template.rstrip
    assert_equal "", template.result
  end
  
  def test_rstrip_removes_lots_of_whitespace
    template.erbout << "a b"
    template.erbout << " " * 100
    template.rstrip
    assert_equal "a b", template.result
  end
end