require File.expand_path('../../test_helper', __FILE__)
require 'line_cook/templater'

class TemplaterTest < Test::Unit::TestCase
  Templater = LineCook::Templater
  
  attr_accessor :templater
  
  def setup
    @templater = Templater.new
  end
  
  #
  # rstrip test
  #
  
  def test_rstrip_rstrips_target
    templater.target << " a b \n "
    templater.rstrip
    assert_equal " a b", templater.to_s
  end
  
  def test_rstrip_removes_all_whitespace_up_to_start
    templater.target << "  \n "
    templater.rstrip
    assert_equal "", templater.to_s
  end
  
  def test_rstrip_removes_lots_of_whitespace
    templater.target << "a b"
    templater.target << " " * 100
    templater.rstrip
    assert_equal "a b", templater.to_s
  end
end