require 'line_cook/utils'

module LineCook
  class Cookbook
    class << self
      def split_path(path)
        path.kind_of?(String) ? path.split(':') : path
      end
    end
    include Utils
    
    FILE_PATTERNS = {
      :attributes  => File.join('attributes', '**', '*.rb'),
      :files       => File.join('files', '**', '*'),
      :definitions => File.join('helpers', '*', '**', '*.erb'),
      :helpers     => File.join('helpers', '**', '*.rb'),
      :recipes     => File.join('recipes', '**', '*.rb'),
      :scripts     => File.join('scripts', '*.yml'),
      :templates   => File.join('templates', '**', '*.erb')
    }
    
    MANIFEST_TYPES = [
      :attributes,
      :files,
      :helpers,
      :recipes,
      :scripts,
      :templates
    ] 
    
    attr_reader :dirs
    attr_reader :files
    
    def initialize(*dirs)
      @dirs = dirs.collect {|dir| File.expand_path(dir) }
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
        MANIFEST_TYPES.each do |type|
          manifest.merge! files[type]
        end
        manifest
      end
    end
  end
end