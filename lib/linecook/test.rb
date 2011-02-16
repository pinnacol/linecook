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
    
    def cookbook_dir
      File.directory?(method_dir) ? method_dir : user_dir
    end
    
    def setup_cookbook(config=cookbook_dir)
      @cookbook = Cookbook.setup(config)
    end
    
    def cookbook
      @cookbook ||= setup_cookbook
    end
    
    def setup_package(env={})
      @package = Package.setup(env, cookbook)
    end
    
    def package
      @package ||= setup_package
    end
    
    def setup_helpers(*helpers)
      @helpers = helpers
    end
    
    def helpers
      @helpers ||= []
    end
    
    def setup_recipe(target_name='recipe')
      recipe = package.reset.setup_recipe(target_name)
      helpers.each {|helper| recipe.extend helper }
      @recipe = recipe
    end
    
    def recipe
      @recipe ||= setup_recipe
    end
    
    def assert_recipe(expected, recipe=setup_recipe, &block)
      recipe.instance_eval(&block) if block_given?
      assert_output_equal expected, recipe.result
      recipe
    end
    
    def assert_recipe_match(expected, recipe=setup_recipe, &block)
      recipe.instance_eval(&block) if block_given?
      assert_alike expected, recipe.result
      recipe
    end
    
    def assert_packages(output=nil)
      relative_dir = method_dir[(user_dir.length + 1)..-1]
      cmd = "#{LINECOOK} test --force --quiet --remote-test-dir 'vm/#{relative_dir}' '#{method_dir}'"
      
      result = sh cmd
      
      _assert_output_equal(output, result, cmd) if output
      assert_equal(0, $?.exitstatus, cmd)
    end
  end
end