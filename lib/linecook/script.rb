require 'linecook/attributes'
require 'linecook/recipe'
require 'tempfile'

module Linecook
  class Script
    CONFIG_KEY   = 'linecook'
    MANIFEST_KEY = 'manifest'
    RECIPES_KEY  = 'recipes'
    REGISTRY_KEY = 'registry'
    
    attr_reader :context
    attr_reader :cache
    
    def initialize(context={})
      @context = context
      @cache   = []
    end
    
    def config
      context[CONFIG_KEY] ||= {}
    end
    
    def manifest
      config[MANIFEST_KEY] ||= {}
    end
    
    def recipes
      recipes = config[RECIPES_KEY] ||= {}
      
      case recipes
      when Hash
        recipes
      when Array
        hash = {}
        recipes.each {|entry| hash[entry] = entry }
        config[RECIPES_KEY] = hash
      else
        raise "invalid recipes: #{recipes.inspect}"
      end
    end
    
    def registry
      config[REGISTRY_KEY] ||= {}
    end
    
    def attributes
      Attributes.new(context)
    end
    
    def tempfile(relative_path, basename=relative_path)
      tempfile = Tempfile.new(relative_path)
      
      registry[tempfile.path] = relative_path
      cache << tempfile
      
      tempfile
    end
    
    def source_path(*relative_path)
      path = File.join(*relative_path)
      manifest[path] or raise "no such file in manifest: #{path.inspect}"
    end
    
    def close
      cache.each do |obj|
        obj.close unless obj.closed?
      end
    end
    
    def clear
      registry.clear
      cache.clear
    end
    
    def build
      recipes.each_pair do |recipe_name, target_name|
        recipe = Recipe.new(recipe_name, manifest, context, registry)
        recipe.evaluate
        cache << recipe
      end
    end
  end
end