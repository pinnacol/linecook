module LineCook
  class Cookbook
    class << self
      def split_path(path)
        path.kind_of?(String) ? path.split(':') : path
      end
    end
    
    FILE_PATTERNS = {
      :attributes => [File.join('**', '*.rb')],
      :files      => [File.join('**', '*')],
      :helpers    => [File.join('**', '*.erb'), File.join('**', '_*.rb')],
      :recipes    => [File.join('**', '*.rb')],
      :scripts    => [File.join('*.yml')],
      :templates  => [File.join('**', '*.erb')]
    }
    
    attr_reader :path
    attr_reader :manifest
    
    def initialize(config={})
      path  = self.class.split_path(config['path'] || ['.'])
      @path = path.collect {|dir| File.expand_path(dir) }
      @manifest = Hash.new {|hash, key| hash[key] = glob(key, *FILE_PATTERNS[key]) }
    end
    
    def [](key)
      manifest[key]
    end
    
    def glob(type, *patterns)
      files = {}
      
      path.each do |dir|
        base = File.join(dir, type.to_s)
        
        patterns.each do |pattern|
          Dir.glob(File.join(base, pattern)).each do |path|
            next unless File.file?(path)
            
            relative_path = path[(base.length+1)..-1]
            files[relative_path] ||= path
          end
        end
      end
      
      files
    end
  end
end