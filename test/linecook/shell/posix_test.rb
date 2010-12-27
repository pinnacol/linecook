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
  
  #
  # heredoc test
  #
  
  def test_heredoc_creates_a_heredoc_statement_using_the_block
    assert_recipe %q{
      << EOF
      line one  
        line two
      EOF
    } do
      heredoc 'EOF' do
        script.puts 'line one  '
        script.puts '  line two'
      end
    end
  end
end