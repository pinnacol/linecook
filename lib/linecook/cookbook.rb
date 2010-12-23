require 'linebook'

module Linecook
  class Cookbook
    class << self
      def config_file(dir)
        Dir.glob(File.join(dir, '{Ll}inebook')).first
      end
        
      def init(dir)
        path   = config_file(dir)
        config = path ? YAML.load_file(path) : nil
        new(config || {})
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
    
    PATTERNS = [
      ['', File.join('attributes', '**', '*.rb')],
      ['', File.join('files',      '**', '*')],
      ['', File.join('helpers',    '**', '*.rb')],
      ['', File.join('recipes',    '**', '*.rb')],
      ['', File.join('templates',  '**', '*.erb')]
    ]
    
    attr_reader :config
    
    def initialize(config)
      @config = {
         'patterns' => PATTERNS,
         'paths' => ['.'],
         'gems'  => self.class.gems
       }.merge(config)
    end
    
    def manifest
      @manifest ||= __manifest(config)
    end
  end
end