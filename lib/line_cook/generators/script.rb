require 'tap/generator/base'
require 'line_cook/recipe'
require 'json'
require 'open-uri'

module LineCook
  module Generators
    # :startdoc::generator 
    class Script < Tap::Generator::Base
      config :attrs_url, nil, :long => :attrs         # the user attributes url
    
      module FilePatch
        def file(target, options={})
          options[:source] ||= begin
            source_file = Tempfile.new('generate')
            yield(source_file) if block_given?
            source_file.close
            source_file.path
          end
        
          source = options[:source]
          target = path(target)
        
          copy_file = true
          msg = case
          when !File.exists?(target)
            :create
          when FileUtils.cmp(source, target)
            :exists
          when force_file_collision?(target)
            :force
          else
            copy_file = false
            :skip
          end
        
          log_relative msg, target
          if copy_file && !pretend
            dir = File.dirname(target)
            FileUtils.mkdir_p(dir, :mode => 0755) unless File.exists?(dir) 
            FileUtils.cp(source, target)
            FileUtils.chmod(0644, target)
          end
        
          target
        end
      end
    
      def manifest(m, name)
        m.on(:generate) do
          extend FilePatch
        end
      
        recipe = Recipe.new(name, :attrs => load_attrs(attrs_url))
        recipe.evaluate(name)
        recipe.close
      
        recipe.registry.each_pair do |source, target|
          target = destination_root.path('scripts', target)
          m.file target, :source => source
        end
      end
    
      def load_attrs(url)
        url.nil? ? {} : open(url) {|io| JSON.parse(io.read, :symbolize_names => true) }
      end
    end
  end
end
