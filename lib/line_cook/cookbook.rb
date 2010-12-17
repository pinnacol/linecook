module LineCook
  class Cookbook
    class << self
      def split_path(path)
        path.kind_of?(String) ? path.split(':') : path
      end
    end
    
    FILE_PATTERNS = [
      File.join('attributes', '**', '*.rb'),
      File.join('files', '**', '*'),
      File.join('helpers', '**', '*.erb'), File.join('helpers', '**', '_*.rb'),
      File.join('recipes', '**', '*.rb'),
      File.join('scripts', '*.yml'),
      File.join('templates', '**', '*.erb')
    ]
    
    attr_reader :path
    
    def initialize(config={})
      path  = self.class.split_path(config['path'] || ['.'])
      @path = path.collect {|dir| File.expand_path(dir) }
      @manifest = nil
    end
    
    def glob(*patterns)
      files = {}
      
      path.each do |dir|
        patterns.each do |pattern|
          Dir.glob(File.join(dir, pattern)).each do |path|
            next unless File.file?(path)
            
            relative_path = path[(dir.length+1)..-1]
            files[relative_path] ||= path
          end
        end
      end
      
      files
    end
    
    def manifest
      @manifest ||= glob(*FILE_PATTERNS)
    end
    
    def subset(type)
      base = "#{type}/"
      
      files = {}
      manifest.each_pair do |relative_path, full_path|
        if relative_path.index(base) == 0
          relative_path = relative_path[base.length..-1]
          files[relative_path] = full_path
        end
      end
      files
    end
  end
end