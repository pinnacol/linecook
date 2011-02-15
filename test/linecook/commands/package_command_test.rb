require File.expand_path('../../../test_helper', __FILE__)
require 'linecook/commands/package'
require 'linecook/test/file_test'
require 'linecook/test/shell_test'

class PackageCommandTest < Test::Unit::TestCase
  Package = Linecook::Commands::Package
  
  include Linecook::Test::FileTest
  include Linecook::Test::ShellTest
  
  attr_accessor :cmd
  
  def setup
    super
    @cmd = Package.new(:quiet => true)
  end
  
  #
  # process test
  #
  
  def test_process_builds_package_file
    prepare('recipes/example.rb') do |io|
      io << 'target << "content"' 
    end
    
    prepare('packages/vbox.yml') do |io|
      config = {"linecook" => {"package" => {"recipes" => "example"}}}
      YAML.dump(config, io)
    end
    
    Dir.chdir(method_dir) do
      package_dir = cmd.process('packages/vbox.yml')
      assert_equal "content", File.read("#{package_dir}/example")
    end
  end
  
  def test_process_guesses_package_file_for_name
    prepare('recipes/example.rb') do |io|
      io << 'target << "content"' 
    end
    
    prepare('packages/vbox.yml') do |io|
      config = {"linecook" => {"package" => {"recipes" => "example"}}}
      YAML.dump(config, io)
    end
    
    Dir.chdir(method_dir) do
      cmd.guess_name = true
      package_dir = cmd.process('vbox')
      assert_equal "content", File.read("#{package_dir}/example")
    end
  end
end