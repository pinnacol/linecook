require 'linecook/attributes'
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
  end
end