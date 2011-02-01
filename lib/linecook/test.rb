require 'linecook/cookbook'
require 'linecook/package'
require 'linecook/test/vm_test'
require 'linecook/test/regexp_escape'
require 'linecook/utils'

module Linecook
  module Test
    include VmTest
    
    attr_writer :cookbook
    attr_writer :package
    
    def timestamp
      @timestamp ||= Time.now.strftime("%Y%m%d%H%M%S")
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
    
    def build_options
      {
        :env         => {},
        :target_path => 'recipe',
        :export_dir  => 'package'
      }
    end
    
    def build_package(options={}, &block)
      options = build_options.merge(options)
      
      setup_package options[:env]
      
      if block_given?
        recipe = setup_recipe options[:target_path]
        recipe.result(&block)
      end
      
      package.build
      
      if export_dir = path(options[:export_dir])
        package.export export_dir
      end
      
      package
    end
    
    def transfer_package(package)
      pkg_files = package.registry.values
      
      export_dir = File.dirname(pkg_files.sort_by {|path| path.length }.first)
      if pkg_files.all? {|path| path.index(export_dir) == 0 }
        pkg_files = [export_dir]
      end
      
      scp pkg_files, remote_method_dir
    end
    
    def check_package(remote_script, options={})
      with_each_vm(options) do 
        transfer_package(options[:package] || package)
        assert_remote_script(remote_script, options)
      end
    end
  end
end