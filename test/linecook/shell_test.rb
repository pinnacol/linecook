require File.expand_path('../../test_helper', __FILE__)
require 'linecook/shell'
require 'linecook/test'

class ShellTest < Test::Unit::TestCase
  include Linecook::Test
  
  def recipe
    super.extend Linecook::Shell
  end
  
  #
  # shebang test
  #
  
  def test_shebang_adds_shebang_line
    assert_recipe_match %q{
      #! /bin/bash
      :...:
    } do
      shebang '/bin/bash'
    end
  end
end