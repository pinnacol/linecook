require File.expand_path('../../../test_helper', __FILE__) 
require 'linecook/commands/preview'
require 'linecook/test'

class PreviewCommandTest < Test::Unit::TestCase
  include Linecook::Test
  
  Preview = Linecook::Commands::Preview
  
  attr_accessor :cmd
  
  def setup
    super
    @cmd = Preview.new
  end
  
  #
  # cmd test
  #
  
  def test_preview_prints_preview_of_a_recipe
    prepare('recipes/example.rb') do |io|
      io << "target.puts 'content'"
    end
    
    assert_script %Q{
      % ruby #{LINECOOK} preview example --project-dir '#{method_dir}'
      \033[0;34m--[example]\033[0m
      content
      \033[0;34m--[example]--\033[0m
    }
  end
end
