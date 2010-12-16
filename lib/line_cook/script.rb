require 'json'

module LineCook
  class Script
    class << self
      def each_script(dir, &block)
        Dir.glob("#{dir}/**/*.js").each do |path| 
          next unless File.file?(path)
          
          attrs = JSON.parse(File.read(path), :symbolize_names => true)
          yield path, new(attrs)
        end
      end
    end
    
    attr_reader :data
    
    def initialize(data)
      @data = data
    end
    
    def attrs
      data[:attrs] || {}
    end
    
    def recipes
      data[:recipes] || []
    end
  end
end