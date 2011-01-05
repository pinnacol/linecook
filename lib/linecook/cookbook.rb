require 'linecook/utils'
require 'open-uri'

module Linecook
  class Cookbook
    class << self
      def config_file(dir)
        Dir.glob(File.join(dir, '{C,c}ookbook')).first
      end
        
      def init(dir, *overrides)
        defaults = load_config config_file(dir)
        overrides.collect! {|uri| load_config(uri) }
        
        config = Utils.serial_merge(defaults, *overrides)
        new(dir, config)
      end
      
      def load_config(uri)
        uri ? open(uri) {|io| YAML.load_stream(io).documents.first } : {}
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
    
    include Utils
    
    NAMESPACE = 'linebook'
    PATTERNS  = [
      File.join('attributes', '**', '*.rb'),
      File.join('files',      '**', '*'),
      File.join('recipes',    '**', '*.rb'),
      File.join('templates',  '**', '*.erb')
    ]
    
    attr_reader :dir
    attr_reader :config
    
    def initialize(dir='.', config = {})
      @dir = File.expand_path(dir)
      @config = {
         'manifest'  => {},
         'paths'     => ['.'],
         'gems'      => self.class.gems,
         'namespace' => NAMESPACE
       }.merge(config)
    end
    
    def namespace
      config['namespace']
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
    
    def each_helper
      helpers_dir = File.expand_path('helpers', dir)
      lib_dir = File.expand_path('lib', dir)
      
      sources = {}
      Dir.glob("#{helpers_dir}/**/*").each do |source|
        next if File.directory?(source)
        (sources[File.dirname(source)] ||= []) << source
      end
      
      sources.each_pair do |dir, sources|
        name = dir[(helpers_dir.length+1)..-1]
        const_path = name ? File.join(namespace, name) : namespace
        
        target  = File.join(lib_dir, "#{const_path}.rb")
        sources = sources + [dir]
        
        yield sources, target, camelize(const_path)
      end
    end
    
    def each_script
      scripts_dir = File.expand_path('scripts', dir)
      
      Dir.glob("#{scripts_dir}/*.yml").each do |source|
        name   = File.basename(source).chomp('.yml')
        target = File.join(scripts_dir, name)
        
        yield source, target, name
      end
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