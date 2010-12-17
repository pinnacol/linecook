require 'line_cook/utils'

module LineCook
  class Cookbook
    class << self
      def split_path(path)
        path.kind_of?(String) ? path.split(':') : path
      end
    end
    include Utils
    
    FILE_PATTERNS = [
      File.join('attributes', '**', '*.rb'),
      File.join('files', '**', '*'),
      File.join('helpers', '*', '**', '*.erb'), File.join('helpers', '*', '**', '_*.rb'),
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
    
    def each_helper
      helpers = {}
      
      manifest.each_pair do |relative_path, source|
        next unless relative_path.index('helpers') == 0
        
        segments = relative_path.chomp('.erb').split(File::SEPARATOR)
        const_path = segments[1..-2].join(File::SEPARATOR)
        
        (helpers[const_path] ||= []) << source
      end
      
      helpers.each_pair do |const_path, sources|
        target  = File.join('helpers', "#{const_path}.rb")
        builder = lambda do
          const_name = camelize(const_path)
          content = Helper.new(sources).build(const_name)
          
          target_dir = File.dirname(target)
          unless File.exists?(target_dir)
            FileUtils.mkdir_p(target_dir) 
          end

          File.open(target, 'w') {|io| io << content }
        end
        
        # boo
        manifest[target] = File.expand_path(target)
        
        yield sources, target, builder
      end
    end
    
    def each_script
      manifest.each_pair do |relative_path, source|
        next unless relative_path.index('scripts') == 0
        
        target  = relative_path.chomp('.yml')
        builder = lambda do
          FileUtils.rm_r(target) if File.exists?(target)
          
          
          attrs = YAML.load_file(source)
          Script.new(self, attrs).build_to(target) do |s, t|
            td = File.dirname(t)
            FileUtils.mkdir_p(td) unless File.exists?(td)
            FileUtils.cp(s, t)
          end
        end
        
        yield [source], target, builder
      end
    end
  end
end