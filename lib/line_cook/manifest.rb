require 'line_cook/helper'
require 'line_cook/recipe'
require 'line_cook/script'

module LineCook
  class Manifest
    FILE_PATTERNS = {
      :attributes => [File.join('**', '*.rb')],
      :files      => [File.join('**', '*')],
      :helpers    => [File.join('**', '*.erb'), File.join('**', '_*.rb')],
      :recipes    => [File.join('**', '*.rb')],
      :scripts    => [File.join('*.js')],
      :templates  => [File.join('**', '*.erb')]
    }
    
    attr_reader :dirs
    
    def initialize(*dirs)
      @dirs  = dirs.collect {|dir| File.expand_path(dir) }
      @store = Hash.new {|hash, key| hash[key] = glob(key, *FILE_PATTERNS[key]) }
    end
    
    def [](key)
      @store[key]
    end
    
    def glob(type, *patterns)
      files = {}
      
      dirs.each do |dir|
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