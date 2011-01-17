require 'linecook/cookbook'
require 'linecook/package'
require 'linecook/test/file_test'
require 'linecook/test/shell_test'
require 'linecook/test/regexp_escape'
require 'linecook/utils'

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
    
    def script(options={}, &block)
      options = {
        :target_path => 'recipe',
        :export_dir  => path('packages')
      }.merge!(options)
      
      target_path = options[:target_path]
      export_dir  = options[:export_dir]
      
      recipe = setup_recipe(target_path)
      recipe.result(&block)
      
      registry = package.export(export_dir)
      registry[target_path]
    end
    
    def script_test(cmd, options={}, &block)
      options = {
        :variable   => 'SCRIPT',
        :export_dir => path('packages')
      }.merge!(options)
      
      path = script(options, &block)
      export_dir = options[:export_dir]
      variable   = options[:variable]
      
      Dir.chdir(export_dir) do
        with_env variable => path do
          sh_test(cmd)
        end
      end
    end
  end
end