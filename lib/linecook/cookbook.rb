require 'linecook/package'
require 'yaml'

module Linecook
  class Cookbook
    class << self
      def config_file(dir)
        Dir.glob(File.join(dir, '{C,c}ookbook')).first
      end
        
      def init(dir)
        path   = config_file(dir)
        config = path ? YAML.load_file(path) : nil
        
        new(dir, config || {})
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
    
    PATTERNS  = [
      File.join('attributes', '**', '*.rb'),
      File.join('files',      '**', '*'),
      File.join('recipes',    '**', '*.rb'),
      File.join('templates',  '**', '*.erb')
    ]
    
    attr_reader :dir
    attr_reader :config
    
    def initialize(dir='.', config={})
      @dir = File.expand_path(dir)
      @config = {
         'manifest' => {},
         'paths'    => ['.'],
         'gems'     => self.class.gems
       }.merge(config)
    end
    
    def manifest
      @manifest ||= begin
        manifest  = {}
        
        paths = split config['paths']
        gems  = split config['gems']
        gems  = resolve gems
        
        (gems + paths).each do |path|
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
        
        overrides = config['manifest']
        manifest.merge!(overrides)
        manifest
      end
    end
    
    def env(*uris)
      Package.env(manifest, *uris)
    end
    
    private
    
    def split(str) # :nodoc:
      str.kind_of?(String) ? str.split(':') : str
    end
    
    def resolve(gems) # :nodoc:
      return gems if gems.empty?
      specs = latest_specs
      
      gems.collect do |name| 
        spec = specs[name] or raise "no such gem: #{name.inspect}"
        spec.full_gem_path
      end
    end
    
    def latest_specs # :nodoc:
      latest = {}
      Gem.source_index.latest_specs.each do |spec|
        latest[spec.name] = spec
      end
      latest
    end
  end
end