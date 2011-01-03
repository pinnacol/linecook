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
    
    def tempfile(relative_path, name=relative_path)
      tempfile = Tempfile.new(name)
      
      register(tempfile.path, relative_path)
      cache << tempfile
      
      tempfile
    end
    
    def source_path(*relative_path)
      path = File.join(*relative_path)
      manifest[path] or raise "no such file in manifest: #{path.inspect}"
    end
    
    def register(source_path, relative_path=nil)
      relative_path ||= File.basename(source_path)
      dirname = File.dirname(relative_path)
      
      count = 0
      registry.each_value do |path|
        if path.index(dirname) == 0
          count += 1
        end
      end
      
      if count > 0
        basename = File.basename(relative_path)
        relative_path = File.join(dirname, "#{count}-#{basename}")
      end
      
      registry[source_path] = relative_path
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
        recipe = Recipe.new(recipe_name, self)
        recipe.evaluate
        cache << recipe
      end
    end
    
    def results
      registry.invert
    end
  end
end