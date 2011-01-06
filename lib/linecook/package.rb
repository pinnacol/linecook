require 'linecook/utils'
require 'tempfile'

module Linecook
  class Package
    class << self
      def load_env(path)
        (path ? YAML.load_file(path) : nil) || {}
      end
      
      def env(manifest, path)
        default   = {CONFIG_KEY => {MANIFEST_KEY => manifest}}
        overrides = load_env(path)
        Utils.serial_merge(default, overrides)
      end
      
      def init(env={})
        env.kind_of?(Package) ? env : new(env)
      end
    end
    
    CONFIG_KEY    = 'linecook'
    MANIFEST_KEY  = 'manifest'
    REGISTRY_KEY  = 'registry'
    CACHE_KEY     = 'cache'
    FILES_KEY     = 'files'
    TEMPLATES_KEY = 'templates'
    RECIPES_KEY   = 'recipes'
    PATHS_KEY     = 'paths'
    GEMS_KEY      = 'gems'
    
    attr_reader :env
    
    def initialize(env={})
      @env = env
    end
    
    def config
      env[CONFIG_KEY] ||= {}
    end
    
    def cache
      config[CACHE_KEY] ||= {}
    end
    
    def manifest
      config[MANIFEST_KEY] ||= {}
    end
    
    def registry
      config[REGISTRY_KEY] ||= {}
    end
    
    def reverse_registry
      cache[:reverse_registry] ||= {}
    end
    
    def tempfiles
      cache[:tempfiles] ||= []
    end
    
    def register(source_path, build_path=nil)
      source_path = File.expand_path(source_path)
      build_path ||= File.basename(source_path)
      
      count = 0
      registry.each_key do |path|
        if path.kind_of?(String) && path.index(build_path) == 0
          count += 1
        end
      end
      
      if count > 0
        build_path = "#{build_path}.#{count}"
      end
      
      registry[build_path] = source_path
      reverse_registry[source_path.to_sym] = build_path
      
      build_path
    end
    
    def registered?(source_path)
      source_path = File.expand_path(source_path)
      reverse_registry.has_key?(source_path.to_sym)
    end
    
    def built?(build_path)
      registry.has_key?(build_path)
    end
    
    def tempfile?(source_path)
      tempfiles.find {|tempfile| tempfile.path == source_path }
    end
    
    def build(build_path, source_path=nil)
      case
      when built?(build_path)
        raise "already built: #{build_path}"
        
      when source_path
        register(source_path, build_path)
        
      else
        tempfile = Tempfile.new File.basename(build_path)

        register(tempfile.path, build_path)
        tempfiles << tempfile

        tempfile
      end
    end
    
    def build_path(source_path)
      source_path = File.expand_path(source_path)
      reverse_registry[source_path.to_sym]
    end
    
    def source_path(build_path)
      registry[build_path]
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
    
    def export(dir, options={})
      close
      
      options = {
        :allow_move => true
      }.merge(options)
      
      allow_move = options[:allow_move]
      
      results = {}
      registry.each_pair do |build_path, source_path|
        target_path = File.join(dir, build_path)
        target_dir  = File.dirname(target_path)
        
        unless File.exists?(target_dir)
          FileUtils.mkdir_p(target_dir)
        end
        
        if allow_move && tempfile?(source_path)
          FileUtils.mv(source_path, target_path)
        else
          FileUtils.cp(source_path, target_path)
        end
        
        results[build_path] = target_path
      end
      results
    end
    
    def close
      tempfiles.each do |tempfile|
        tempfile.close unless tempfile.closed?
      end
      self
    end
    
    private
    
    def normalize(key)
      obj = config[key]
      
      case obj
      when Hash
        obj
        
      when nil
        config[key] = {}
        
      when Array
        hash = {}
        obj.each {|entry| hash[entry] = entry }
        config[key] = hash
      
      when String
        config[key] = obj.split(':')
        normalize(key)
      
      else
        raise "invalid #{key}: #{obj.inspect}"
      end
    end
  end
end