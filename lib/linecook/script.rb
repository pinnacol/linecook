require 'linecook/recipe'
require 'yaml'

module Linecook
  class Script
    attr_reader :manifest
    attr_reader :attrs
    
    def initialize(manifest={}, attrs={})
      @manifest = manifest
      @attrs = attrs
    end
    
    def config
      attrs['linecook'] ||= {
        'script_name' => 'linecook',
        'recipe_name' => 'linecook'
      }
    end
    
    def script_name
      config['script_name'] or raise "no script name specified"
    end
    
    def recipe_name
      config['recipe_name'] or raise "no recipe name specified"
    end
    
    def recipe
      @recipe ||= Recipe.new(
        :script_name => script_name, 
        :manifest => manifest, 
        :attrs => attrs
      )
    end
    
    def build_to(dir, options={})
      if File.exists?(dir)
        raise "already exists: #{dir}" unless options[:force]
        FileUtils.rm_r(dir)
      end
      
      unless recipe.closed?
        recipe.evaluate(recipe_name)
        recipe.close
      end
      
      recipe.registry.each_pair do |source, target|
        target = File.join(dir, target)
        
        target_dir = File.dirname(target)
        FileUtils.mkdir_p(target_dir) unless File.exists?(target_dir)
        
        FileUtils.cp(source, target)
      end
    end
  end
end