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
        :config_file => File.expand_path('config/ssh', user_dir),
        :ssh_host => 'vbox'
      }.merge(options)
      
      build(options, &block)
      
      source, target = path('packages'), method_name
      sh("scp -q -r -F '#{options[:config_file]}' '#{source}' '#{options[:ssh_host]}:#{target}'")
      
      options[:prefix] = "ssh -q -F '#{options[:config_file]}' '#{options[:ssh_host]}' -- #{options[:prefix]}"
      sh_test(cmd, options)
    end
  end
end