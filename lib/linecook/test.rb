require 'linecook/cookbook'
require 'linecook/package'
require 'linecook/test/file_test'
require 'linecook/test/shell_test'
require 'linecook/test/regexp_escape'
require 'linecook/utils'
require 'linecook/vbox'

module Linecook
  module Test
    include FileTest
    include ShellTest
    
    attr_writer :cookbook
    attr_writer :package
    
    def cookbook_dir
      user_dir
    end
    
    def cookbook
      @cookbook ||= Cookbook.init(cookbook_dir)
    end
    
    def setup_package(env={})
      @package = Package.init(env, cookbook)
    end
    
    def package
      @package ||= setup_package
    end
    
    def setup_recipe(target_path='recipe')
      @recipe = package.reset.recipe(target_path)
    end
    
    def recipe
      @recipe ||= setup_recipe
    end
    
    def assert_recipe(expected, &block)
      recipe = setup_recipe
      assert_output_equal expected, recipe.result(&block)
      recipe
    end
    
    def assert_recipe_match(expected, &block)
      recipe = setup_recipe
      assert_alike expected, recipe.result(&block)
      recipe
    end
    
    def build(options={}, &block)
      options = {
        :env         => {},
        :target_path => 'recipe',
        :export_dir  => path('packages')
      }.merge(options)
      
      setup_package options[:env]
      
      if block_given?
        recipe = setup_recipe options[:target_path]
        recipe.result(&block)
      end
      
      package.export options[:export_dir]
      package
    end
    
    def script_test(cmd, options={}, &block)
      options = {
        :export_dir => path('packages')
      }.merge(options)
      
      build(options, &block)
      
      Dir.chdir(options[:export_dir]) do
        sh_test(cmd, options)
      end
    end
    
    def vbox_test(cmd, options={}, &block)
      options = {
        :vmname => 'vbox',
        :snapshot => 'base',
        :export_dir => path('packages')
      }.merge(options)
      
      build(options, &block)
      
      vbox = Vbox.new options[:vmname]
      begin
        vbox.stop if vbox.running?
        vbox.reset options[:snapshot]
        vbox.start
        vbox.share options[:export_dir]
        
        commands(cmd, options).each do |command, status, expected|
          result = vbox.ssh(command, options)
        
          if status
            assert_equal status, $?.exitstatus
          end
        
          unless expected.empty?
            assert_equal(expected.join, result, command)
          end
        end
      ensure
        vbox.stop if vbox.running?
      end
    end
  end
end