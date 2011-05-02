require 'linecook/utils'
require 'lazydoc'

module Linecook
  class Cookbook
    class << self
      def config_file(project_dir='.')
        Dir.glob(File.join(project_dir, '{C,c}ookbook')).first
      end
      
      def setup(config={}, project_dir='.')
        unless config.kind_of?(Hash)
          config = Utils.load_config(config)
        end
        
        config[PATHS_KEY] ||= [project_dir]
        config[GEMS_KEY]  ||= gems
        
        new(config, project_dir)
      end
      
      def init(project_dir='.')
        setup config_file(project_dir), project_dir
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
    REWRITE_KEY   = 'rewrite'
    
    PATTERNS  = {
      'attributes' => ['attributes', '.rb'],
      'files'      => ['files'],
      'recipes'    => ['recipes', '.rb'],
      'templates'  => ['templates']
    }
    
    attr_reader :project_dir
    attr_reader :config
    
    def initialize(config={}, project_dir='.')
      @project_dir = project_dir
      @config = config
    end
    
    def paths
      Utils.arrayify config[PATHS_KEY]
    end
    
    def gems
      Utils.arrayify config[GEMS_KEY]
    end
    
    def rewrites
      config[REWRITE_KEY]
    end
    
    def overrides
      config[MANIFEST_KEY]
    end
    
    def full_gem_paths
      return [] if gems.empty?
      specs = latest_specs
      
      gems.collect do |name| 
        spec = specs[name] or raise "no such gem: #{name.inspect}"
        spec.full_gem_path
      end
    end
    
    def rewrite(manifest)
      replacements = {}
      
      rewrites.each_pair do |pattern, substitution|
        manifest.keys.each do |key|
          replacement = key.sub(pattern, substitution)
          next if key == replacement
          raise "multiple replacements for: #{key}" if replacements.has_key?(key)
          
          replacements[key] = replacement
        end
      end if rewrites
      
      replacements.each do |key, replacement|
        manifest[replacement] = manifest.delete(key)
      end
      
      manifest
    end
    
    def glob(*paths)
      manifest = Hash.new {|hash, key| hash[key] = {} }
      
      paths.each do |path|
        PATTERNS.each_pair do |type, (dirname, extname)|
          resource_dir = File.expand_path(File.join(path, dirname), project_dir)
          
          pattern = File.join(resource_dir, "**/*#{extname}")
          
          Dir.glob(pattern).each do |full_path|
            next unless File.file?(full_path)
            
            name = relative_path(resource_dir, full_path)
            name.chomp!(extname) if extname
            
            manifest[type][name] = full_path
          end
        end
      end
      
      manifest
    end
    
    def manifest
      manifest = glob(*(full_gem_paths + paths))
      
      if overrides
        manifest = Utils.deep_merge(manifest, overrides)
      end
      
      manifest.each_key do |key|
        manifest[key] = rewrite manifest[key]
      end
      
      manifest
    end
    
    def merge(config={})
      duplicate = dup
      dup.config.merge!(config)
      dup
    end
    
    private
    
    def relative_path(dir, path) # :nodoc:
      start = dir.length + 1
      path[start, path.length - start]
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