module Linecook
  class Script
    CONFIG_KEY   = 'linecook'
    MANIFEST_KEY = 'manifest'
    RECIPES_KEY  = 'recipes'
    REGISTRY_KEY = 'registry'
    
    attr_reader :context
    
    def initialize(context={})
      @context = context
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
  end
end