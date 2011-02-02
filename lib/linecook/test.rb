require 'linecook/cookbook'
require 'linecook/package'
require 'linecook/test/vm_test'

module Linecook
  module Test
    include VmTest
    
    DEFAULT_HOST = ENV['LINECOOK_TEST_HOST'] || 'vbox'
    
    attr_writer :cookbook
    attr_writer :package
    
    def setup
      super
      set_vm DEFAULT_HOST
    end
    
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
    
    def build_recipe(target_path='recipe', &block)
      setup_recipe(target_path).instance_eval(&block)
    end
    
    def build_package(env={}, options={}, &block)
      options = {
        :target_path => 'recipe',
        :export_dir  => 'package'
      }.merge(options)
      
      package = setup_package(env)
      
      if block_given?
        build_recipe(options[:target_path], &block)
      end
      
      package.build
      
      if export_dir = options[:export_dir]
        package.export path(export_dir)
      end
      
      package
    end
    
    def transfer_package(package=self.package, remote_dir=remote_method_dir)
      pkg_files = package.registry.values
      
      export_dir = File.dirname(pkg_files.sort_by {|path| path.length }.first)
      if pkg_files.all? {|path| path.index(export_dir) == 0 }
        pkg_files = [export_dir]
      end
      
      scp pkg_files, remote_dir
    end
    
    def assert_recipe(expected, recipe=self.recipe, &block)
      recipe.build(&block) if block_given?
      assert_output_equal expected, recipe.result
      recipe
    end
    
    def assert_recipe_match(expected, recipe=self.recipe, &block)
      recipe.build(&block) if block_given?
      assert_alike expected, recipe.result
      recipe
    end
    
    def check_package(remote_script, options={})
      options = {
        :package    => package,
        :remote_dir => remote_method_dir
      }.merge(options)
      
      vm_setup
      transfer_package options[:package], options[:remote_dir]
      assert_remote_script(remote_script, options)
    end
  end
end