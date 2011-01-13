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
    
    def build(env={})
      package = Package.init(env, cookbook)
      package.build
      package.export File.join(method_dir, 'packages')
      package
    end
    
    def setup_recipe
      @recipe = package.reset.recipe
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
    
    def script(export_dir=method_dir, &block)
      recipe = setup_recipe
      recipe.result(&block)
      
      registry = package.export export_dir
      registry[recipe.target_name]
    end
    
    def script_test(cmd, variable='SCRIPT', &block)
      export_dir = path('packages')
      path = script(export_dir, &block)
      
      Dir.chdir(export_dir) do
        with_env variable => path do
          sh_test(cmd)
        end
      end
    end
  end
end