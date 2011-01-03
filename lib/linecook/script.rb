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
    attr_accessor :scope
    
    def initialize(context={})
      @context = context
      @cache   = []
      @scope   = nil
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
    
    def tempfile(relative_path)
      tempfile = Tempfile.new File.basename(relative_path)
      
      register(tempfile.path, relative_path)
      cache << tempfile
      
      tempfile
    end
    
    def register(source_path, relative_path = File.basename(source_path))
      if registry.has_key?(source_path)
        raise "already registered: #{source_path.inspect}"
      end
      
      count = 0
      registry.each_value do |path|
        if path.index(relative_path) == 0
          count += 1
        end
      end
      
      if count > 0
        relative_path = "#{relative_path}.#{count}"
      end
      
      if scope
        relative_path = File.join(scope, relative_path)
      end
      
      registry[source_path] = relative_path
    end
    
    def with_scope(scope)
      current = self.scope
      
      begin
        self.scope = scope
        yield
      ensure
        self.scope = current
      end
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
        with_scope "#{recipe_name}.d" do
          recipe.evaluate
          cache << recipe
        end
      end
    end
    
    def results
      registry.invert
    end
  end
end