module Linecook
  class Package
    CONFIG_KEY    = 'linecook'
    MANIFEST_KEY  = 'manifest'
    REGISTRY_KEY  = 'registry'
    FILES_KEY     = 'files'
    TEMPLATES_KEY = 'templates'
    RECIPES_KEY   = 'recipes'
    
    attr_reader :env
    
    def initialize(env={})
      @env = env
    end
    
    def config
      env[CONFIG_KEY] ||= {}
    end
    
    def manifest
      config[MANIFEST_KEY] ||= {}
    end
    
    def registry
      config[REGISTRY_KEY] ||= {}
    end
    
    def files
      normalize(FILES_KEY)
    end
    
    def templates
      normalize(TEMPLATES_KEY)
    end
    
    def recipes
      normalize(RECIPES_KEY)
    end
    
    private
    
    def normalize(key)
      obj = config[key]
      
      case obj
      when Hash then obj
      when nil  then config[key] = {}
      when Array
        hash = {}
        obj.each {|entry| hash[entry] = entry }
        config[key] = hash
      else raise "invalid #{key}: #{obj.inspect}"
      end
    end
  end
end