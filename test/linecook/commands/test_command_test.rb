require File.expand_path('../../../test_helper', __FILE__) 
require 'linecook/commands/test'
require 'linecook/test'

class TestCommandTest < Test::Unit::TestCase
  include Linecook::Test
  
  Test = Linecook::Commands::Test
  
  attr_accessor :cmd
  
  def setup
    super
    @cmd = Test.new
  end
  
  #
  # cmd test
  #
  
  def test_test_builds_transfers_and_runs_build_and_test_scripts
    prepare('recipes/abox.rb') do |io|
      io.puts "puts 'build'"
      io.puts "target.puts 'echo content > file.txt'"
      
    end
    
    prepare('recipes/abox_test.rb') do |io|
      io.puts "puts 'test'"
      io.puts "target.puts '[ $(cat file.txt) = \"content\" ]'"
    end
    
    prepare('packages/abox.yml') {}
    
    assert_script %Q{
      % ruby #{LINECOOK} test --quiet --remote-test-dir 'vm/test/#{method_name}' '#{method_dir}'
      build
      test
    }
  end
  
  def test_test_exits_with_status_1_for_failed_tests
    prepare('recipes/abox.rb') {}
    
    prepare('recipes/abox_test.rb') do |io|
      io.puts "target.puts 'false'"
    end
    
    prepare('packages/abox.yml') {}
    
    assert_script %Q{
      % ruby #{LINECOOK} test --quiet --remote-test-dir 'vm/test/#{method_name}' '#{method_dir}'  # [1] ...
    }
  end
end
