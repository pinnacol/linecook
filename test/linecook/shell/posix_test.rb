require File.expand_path('../../../test_helper', __FILE__)
require 'linecook/shell/posix'
require 'linecook/test'

class PosixTest < Test::Unit::TestCase
  include Linecook::Test
  
  def recipe
    super.extend Linecook::Shell::Posix
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
      heredoc :delimiter => 'EOF' do
        target.puts 'line one  '
        target.puts '  line two'
      end
    end
  end
  
  def test_heredoc_increments_default_delimiter
    assert_recipe %q{
      << HEREDOC_0
      HEREDOC_0
      << HEREDOC_1
      HEREDOC_1
    } do
      heredoc {}
      heredoc {}
    end
  end
  
  def test_heredoc_quotes_if_specified
    assert_recipe %q{
      << "HEREDOC_0"
      HEREDOC_0
    } do
      heredoc(:quote => true) {}
    end
  end
  
  def test_heredoc_flags_indent_if_specified
    assert_recipe %q{
      <<-HEREDOC_0
      HEREDOC_0
    } do
      heredoc(:indent => true) {}
    end
  end
  
  #
  # not_if test
  #
  
  def test_not_if_reverses_condition
    assert_recipe %q{
      if ! condition
      then
      fi
      
    } do
      not_if('condition') {}
    end
  end
  
  #
  # only_if test
  #
  
  def test_only_if_encapsulates_block_in_if_statement
    assert_recipe %q{
      if condition
      then
        content
      fi
      
    } do
      only_if('condition') { target << 'content' }
    end
  end
end