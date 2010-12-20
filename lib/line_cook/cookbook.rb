require 'line_cook/utils'

module LineCook
  class Cookbook
    class << self
      def split_path(path)
        path.kind_of?(String) ? path.split(':') : path
      end
      
      def cookbook_file(dir)
        File.expand_path('Cookbook', dir)
      end
      
      def init_from(dir)
        attrs = YAML.load_file(cookbook_file(pwd)) || {}
        init(attrs)
      end
      
      def init(attrs)
        require 'rubygems' unless Object.const_defined?(:Gem)
        
        path = attrs['path'] || '.'
        dirs = split_path(path)
        
        gems = attrs['gems'] || Gem.loaded_specs.keys
        gems.each do |gem_name|
          spec = Gem.source_index.find_name(gem_name).last
          dir  = spec.full_gem_path
          dirs << dir if File.exists?(cookbook_file(dir))
        end
        
        new(*dirs)
      end
    end
    include Utils
    
    FILE_PATTERNS = {
      :attributes  => File.join('attributes', '**', '*.rb'),
      :files       => File.join('files', '**', '*'),
      :helpers     => File.join('helpers', '**', '*.rb'),
      :recipes     => File.join('recipes', '**', '*.rb'),
      :templates   => File.join('templates', '**', '*.erb')
    }
    
    attr_reader :dirs
    attr_reader :files
    
    def initialize(*dirs)
      @dirs  = dirs.collect {|dir| File.expand_path(dir) }
      @files = Hash.new do |hash, key| 
        pattern = FILE_PATTERNS[key]
        hash[key] = pattern ? glob(pattern) : nil
      end
      
      @manifest = nil
    end
    
    def [](type)
      files[type]
    end
    
    def glob(pattern)
      files = {}
      
      dirs.each do |dir|
        Dir.glob(File.join(dir, pattern)).each do |path|
          next unless File.file?(path)
          
          relative_path = path[(dir.length+1)..-1]
          files[relative_path] ||= path
        end
      end
      
      files
    end
    
    def manifest
      @manifest ||= begin
        manifest = {}
        FILE_PATTERNS.each_key do |type|
          manifest.merge! files[type]
        end
        manifest
      end
    end
  end
end