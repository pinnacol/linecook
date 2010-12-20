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
      :helpers     => File.join('helpers', '**', '*.rb'),
      :recipes     => File.join('recipes', '**', '*.rb'),
      :templates   => File.join('templates', '**', '*.erb')
    }
    
    attr_reader :work_dir
    attr_reader :source_dirs
    attr_reader :source_files
    
    def initialize(work_dir, *source_dirs)
      @work_dir    = File.expand_path(work_dir)
      @source_dirs = source_dirs.collect {|dir| File.expand_path(dir) }
      @source_dirs.unshift(work_dir)
      
      @source_files = Hash.new do |hash, key| 
        pattern = FILE_PATTERNS[key]
        hash[key] = pattern ? glob(pattern) : nil
      end
      
      @manifest = nil
    end
    
    def [](type)
      source_files[type]
    end
    
    def glob(pattern)
      files = {}
      
      source_dirs.each do |dir|
        Dir.glob(File.join(dir, pattern)).each do |path|
          next unless File.file?(path)
          
          relative_path = path[(dir.length+1)..-1]
          files[relative_path] ||= path
        end
      end
      
      files
    end
    
    def reset(type=nil)
      @manifest = nil
      @sources = nil
      
      if type
        @source_files.delete(type)
      else
        @source_files.clear
      end
      
      self
    end
    
    def manifest
      @manifest ||= begin
        manifest = {}
        FILE_PATTERNS.each_key do |type|
          manifest.merge! source_files[type]
        end
        manifest
      end
    end
    
    def each_helper
      helpers = {}
      
      helpers_dir = File.join(work_dir, 'helpers')
      Dir.glob("#{helpers_dir}/*/**/*.erb").each do |definition|
        const_path = File.dirname(definition)[(helpers_dir.length+1)..-1]
        (helpers[const_path] ||= []) << definition
      end
      
      helpers.each_pair do |const_path, definitions|
        sources = definitions + definitions.collect {|path| File.dirname(path) }
        target  = File.join(work_dir, 'helpers', "#{const_path}.rb")
        helper  = Helper.new(camelize(const_path), definitions)
        
        yield sources, target, helper
      end
    end
    
    def each_script
      pattern = File.join(work_dir, 'scripts', '*.yml')
      Dir.glob(pattern).each do |source|
        name    = File.basename(source).chomp File.extname(source)
        
        sources = [source]
        target  = File.join(work_dir, 'scripts', name)
        script  = LineCook::Script.new(self, YAML.load_file(source))
        
        yield sources, target, script
      end
    end
  end
end