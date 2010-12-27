require File.expand_path('../../../test_helper', __FILE__)
require 'linecook/shell/posix'
require 'linecook/test/helper'

class PosixTest < Test::Unit::TestCase
  include Linecook::Test::Helper
  
  def helper
    Linecook::Shell::Posix
  end
  
  #
  # comment test
  #
  
  def test_comment_writes_a_comment_string
    assert_recipe %q{
      # string
    } do
      comment 'string'
    end
  end
end