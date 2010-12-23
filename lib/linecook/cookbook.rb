require 'linebook'
require 'linecook/utils'

module Linecook
  class Cookbook
    class << self
      def config_file(dir)
        Dir.glob(File.join(dir, '{Ll}inebook')).first
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
    
    include Linebook
    include Utils
    
    PATTERNS = [
      ['', File.join('attributes', '**', '*.rb')],
      ['', File.join('files',      '**', '*')],
      ['', File.join('recipes',    '**', '*.rb')],
      ['', File.join('templates',  '**', '*.erb')]
    ]
    
    attr_reader :dir
    attr_reader :config
    
    def initialize(dir = Dir.pwd, config = {})
      @dir = dir
      @config = {
         'patterns' => PATTERNS,
         'paths' => ['.'],
         'gems'  => self.class.gems
       }.merge(config)
    end
    
    def manifest
      @manifest ||= __manifest(config)
    end
    
    def each_helper
      helpers_dir = File.expand_path('helpers', dir)
      lib_dir = File.expand_path('lib', dir)
      
      Dir.glob("#{helpers_dir}/**/*/").each do |source|
        const_path = File.join('linebook', source[(helpers_dir.length+1)..-2])
        target     = File.join(lib_dir, "#{const_path}.rb")
        
        yield source.chomp('/'), target, camelize(const_path)
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
  end
end