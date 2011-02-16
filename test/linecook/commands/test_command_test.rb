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
  
  def relative_dir
    method_dir[(user_dir.length + 1)..-1]
  end
  
  #
  # cmd test
  #
  
  def test_test_builds_transfers_and_runs_build_and_test_scripts
    prepare('recipes/abox.rb') do |io|
      io.puts "puts 'build'"
      io.puts "target.puts 'echo run'"
      io.puts "target.puts 'echo content > file.txt'"
      
    end
    
    prepare('recipes/abox_test.rb') do |io|
      io.puts "puts 'build test'"
      io.puts "target.puts 'echo run test'"
      io.puts "target.puts '[ $(cat file.txt) = \"content\" ]'"
    end
    
    prepare('packages/abox.yml') {}
    
    assert_script %Q{
      % ruby #{LINECOOK} build --quiet --project-dir '#{method_dir}'
      build
      build test
      % ruby #{LINECOOK} test --quiet --remote-test-dir 'vm/#{relative_dir}' --project-dir '#{method_dir}'
      run
      run test
    }
  end
  
  def test_test_exits_with_status_1_for_failed_tests
    prepare('recipes/abox.rb') {}
    
    prepare('recipes/abox_test.rb') do |io|
      io.puts "target.puts 'false'"
    end
    
    prepare('packages/abox.yml') {}
    
    assert_script %Q{
      % ruby #{LINECOOK} build --quiet --project-dir '#{method_dir}' # ...
      % ruby #{LINECOOK} test --quiet --remote-test-dir 'vm/#{relative_dir}' --project-dir '#{method_dir}'  # [1] ...
    }
  end
  
  def test_test_builds_and_tests_each_package
    ['abox', 'bbox'].each do |box|
      prepare("recipes/#{box}.rb") do |io|
        io.puts "puts 'build #{box}'"
        io.puts "target.puts 'echo run #{box}'"
        io.puts "target.puts 'echo content > file.txt'"
      
      end
    
      prepare("recipes/#{box}_test.rb") do |io|
        io.puts "puts 'build #{box}_test'"
        io.puts "target.puts 'echo run #{box}_test'"
        io.puts "target.puts '[ $(cat file.txt) = \"content\" ]'"
      end
    
      prepare("packages/#{box}.yml") {}
    end
    
    assert_script %Q{
      % ruby #{LINECOOK} build --quiet --project-dir '#{method_dir}'
      build abox
      build abox_test
      build bbox
      build bbox_test
      % ruby #{LINECOOK} test --quiet --remote-test-dir 'vm/#{relative_dir}' --project-dir '#{method_dir}'
      run abox
      run bbox
      run abox_test
      run bbox_test
    }
  end
end
