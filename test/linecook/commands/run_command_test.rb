require File.expand_path('../../../test_helper', __FILE__) 
require 'linecook/commands/run'
require 'linecook/test'

class RunCommandTest < Test::Unit::TestCase
  include Linecook::Test
  
  Run = Linecook::Commands::Run
  
  attr_accessor :cmd
  
  def setup
    super
    @cmd = Run.new
  end
  
  def relative_dir
    method_dir[(user_dir.length + 1)..-1]
  end
  
  #
  # cmd test
  #
  
  def test_run_builds_transfers_and_runs_run_script
    prepare('recipes/abox.rb') do |io|
      io.puts "puts 'build'"
      io.puts "writeln 'echo run'"
    end
    
    prepare('packages/abox.yml') {}
    
    assert_script %Q{
      % ruby #{LINECOOK} build --quiet --project-dir '#{method_dir}'
      build
      % ruby #{LINECOOK} run --quiet --remote-dir 'vm/#{relative_dir}' --project-dir '#{method_dir}'
      run
    }
  end
  
  def test_run_exits_with_status_1_for_failed_script
    prepare('recipes/abox.rb') do |io|
      io.puts "writeln 'exit 8'"
    end
    
    prepare('packages/abox.yml') {}
    
    assert_script %Q{
      % ruby #{LINECOOK} build --quiet --project-dir '#{method_dir}' # ...
      % ruby #{LINECOOK} run --quiet --remote-dir 'vm/#{relative_dir}' --project-dir '#{method_dir}'  # [1] ...
    }
  end
  
  def test_run_exits_with_status_1_for_missing_run_script
    prepare('recipes/not_run.rb') {|io| }
    
    prepare('packages/abox.yml') do |io|
      YAML.dump({
        'linecook' => {
          'package' => {
            'recipes' => ['not_run']
          }
        }
      }, io)
    end
    
    assert_script %Q{
      % ruby #{LINECOOK} build --quiet --project-dir '#{method_dir}' # ...
      % ruby #{LINECOOK} run --quiet --remote-dir 'vm/#{relative_dir}' --project-dir '#{method_dir}'  # [1] ...
    }
  end
  
  def test_run_builds_and_runs_each_package
    ['abox', 'bbox'].each do |box|
      prepare("recipes/#{box}.rb") do |io|
        io.puts "puts 'build #{box}'"
        io.puts "writeln 'echo run #{box}'"
      end
      
      prepare("packages/#{box}.yml") {}
    end
    
    assert_script %Q{
      % ruby #{LINECOOK} build --quiet --project-dir '#{method_dir}'
      build abox
      build bbox
      % ruby #{LINECOOK} run --quiet --remote-dir 'vm/#{relative_dir}' --project-dir '#{method_dir}'
      run abox
      run bbox
    }
  end
end
