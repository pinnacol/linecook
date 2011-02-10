require 'linecook/cookbook'
require 'linecook/package'
require 'linecook/test/file_test'
require 'linecook/test/shell_test'

module Linecook
  module Test
    include FileTest
    include ShellTest
    
    LINECOOK_DIR = File.expand_path('../../..', __FILE__)
    LINECOOK = File.join(LINECOOK_DIR, 'bin/linecook')
    
    attr_writer :cookbook
    attr_writer :package
    
    def cookbook_dir
      user_dir
    end
    
    def cookbook
      @cookbook ||= Cookbook.init(cookbook_dir)
    end
    
    def setup_package(env={})
      @package = Package.setup(env, cookbook)
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
    
    def assert_recipe(expected, recipe=self.recipe, &block)
      recipe.instance_eval(&block) if block_given?
      assert_output_equal expected, recipe.result
      recipe
    end
    
    def assert_recipe_match(expected, recipe=self.recipe, &block)
      recipe.instance_eval(&block) if block_given?
      assert_alike expected, recipe.result
      recipe
    end
  end
end