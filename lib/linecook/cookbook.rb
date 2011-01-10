require 'linecook/utils'

module Linecook
  class Cookbook
    class << self
      def config_file(dir)
        Dir.glob(File.join(dir, '{C,c}ookbook')).first
      end
      
      def init(dir)
        path = config_file(dir)
        new(dir, Utils.load_config(path))
      end
      
      def default
        {
           MANIFEST_KEY => {},
           PATHS_KEY    => ['.'],
           GEMS_KEY     => gems
         }
      end
      
      def gems
        return [] unless Object.const_defined?(:Gem)
        
        Gem.source_index.latest_specs.select do |spec|
          config_file(spec.full_gem_path) != nil
        end.collect do |spec|
          spec.name
        end
      end
    end
    
    MANIFEST_KEY  = 'manifest'
    PATHS_KEY     = 'paths'
    GEMS_KEY      = 'gems'
    
    PATTERNS  = [
      File.join('attributes', '**', '*.rb'),
      File.join('files',      '**', '*'),
      File.join('lib',        '**', '*.rb'),
      File.join('recipes',    '**', '*.rb'),
      File.join('templates',  '**', '*.erb')
    ]
    
    attr_reader :dir
    attr_reader :default_config
    
    def initialize(dir='.', default_config={})
      @dir = File.expand_path(dir)
      @default_config = self.class.default.merge(default_config)
    end
    
    def manifest(config={})
      manifest = {}
      config = default_config.merge(config || {})
      
      paths = split config[PATHS_KEY]
      gems  = split config[GEMS_KEY]
      
      (full_gem_paths(gems) + paths).each do |path|
        path  = File.expand_path(path, dir)
        start = path.length + 1
        
        PATTERNS.each do |pattern|
          Dir.glob(File.join(path, pattern)).each do |full_path|
            next unless File.file?(full_path)
            
            rel_path = full_path[start, full_path.length - start]
            manifest[rel_path] = full_path
          end
        end
      end
      
      if overrides = config[MANIFEST_KEY]
        manifest.merge! overrides
      end
      
      manifest
    end
    
    private
    
    def split(obj) # :nodoc:
      obj.kind_of?(String) ? obj.split(':') : obj
    end
    
    def latest_specs # :nodoc:
      latest = {}
      Gem.source_index.latest_specs.each do |spec|
        latest[spec.name] = spec
      end
      latest
    end
    
    def full_gem_paths(gems) # :nodoc:
      return gems if gems.empty?
      specs = latest_specs
      
      gems.collect do |name| 
        spec = specs[name] or raise "no such gem: #{name.inspect}"
        spec.full_gem_path
      end
    end
  end
end