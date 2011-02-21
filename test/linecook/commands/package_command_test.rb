require File.expand_path('../../../test_helper', __FILE__)
require 'linecook/commands/package'
require 'linecook/test'

class PackageCommandTest < Test::Unit::TestCase
  include Linecook::Test
  
  Package = Linecook::Commands::Package
  
  attr_accessor :cmd
  
  def setup
    super
    @cmd = Package.new(:quiet => true)
  end
  
  #
  # process test
  #
  
  def test_process_builds_package_with_the_specified_name
    prepare('recipes/example.rb') do |io|
      io << 'target << "content"' 
    end
    
    prepare('packages/vbox.yml') do |io|
      config = {"linecook" => {"package" => {"recipes" => "example"}}}
      YAML.dump(config, io)
    end
    
    Dir.chdir(method_dir) do
      package_dir = cmd.process('vbox')
      assert_equal "content", File.read("#{package_dir}/example")
    end
  end
  
  def test_process_allows_package_file_if_specified
    prepare('recipes/example.rb') do |io|
      io << 'target << "content"' 
    end
    
    prepare('path/to/vbox.yml') do |io|
      config = {"linecook" => {"package" => {"recipes" => "example"}}}
      YAML.dump(config, io)
    end
    
    Dir.chdir(method_dir) do
      cmd.file = true
      package_dir = cmd.process('path/to/vbox.yml')
      assert_equal "content", File.read("#{package_dir}/example")
    end
  end
  
  def test_process_guesses_package_config_as_per_host_name
    prepare('recipes/vbox.rb') do |io|
      io << 'target << "run content"'
    end
    
    prepare('recipes/vbox_test.rb') do |io|
      io << 'target << "test content"'
    end
    
    prepare('packages/vbox.yml') {}
    
    Dir.chdir(method_dir) do
      package_dir = cmd.process('vbox')
      
      assert_equal "run content", File.read("#{package_dir}/run")
      assert_equal "test content", File.read("#{package_dir}/test")
    end
  end
end