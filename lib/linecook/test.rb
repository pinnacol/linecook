require 'linecook/cookbook'
require 'linecook/recipe'
require 'linecook/test/file_test'
require 'linecook/test/shell_test'
require 'linecook/test/regexp_escape'
require 'linecook/utils'

module Linecook
  module Test
    include FileTest
    include ShellTest
    
    attr_writer :cookbook
    attr_writer :script
    attr_writer :recipe
    
    def cookbook
      @cookbook ||= Cookbook.init(user_dir)
    end
    
    def manifest
      @manifest ||= cookbook.manifest
    end
    
    def use_method_dir_manifest
      @manifest = Hash.new do |hash, relative_path|
        path = File.join(method_dir, relative_path.to_s)
        hash[relative_path] = File.exists?(path) ? path : nil
      end
    end
    
    def default_env
      {Package::CONFIG_KEY => {Package::MANIFEST_KEY => manifest}}
    end
    
    def recipe
      @recipe ||= Recipe.new('recipe', default_env)
    end
    
    def build(env={})
      env = Utils.deep_merge(default_env, env)
      Recipe.build(env).export File.join(method_dir, 'scripts')
    end
    
    def assert_recipe(expected, &block)
      recipe.instance_eval(&block)
      assert_output_equal expected, recipe.result
    end
    
    def assert_recipe_match(expected, &block)
      recipe.instance_eval(&block)
      assert_alike expected, recipe.result
    end

    def assert_content(expected, build_path)
      registry = recipe.close

      assert_equal true, registry.has_key?(build_path), "not in registry: #{build_path}"
      assert_output_equal expected, File.read(registry[build_path]), build_path
    end
    
    def assert_content_match(expected, build_path)
      registry = recipe.close

      assert_equal true, registry.has_key?(build_path), "not in registry: #{build_path}"
      assert_alike expected, File.read(registry[build_path]), build_path
    end
  end
end