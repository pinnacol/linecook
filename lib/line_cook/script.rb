require 'line_cook/cookbook'
require 'line_cook/recipe'
require 'yaml'

module LineCook
  class Script
    attr_reader :cookbook
    attr_reader :attrs
    
    def initialize(cookbook = Cookbook.new, attrs = {})
      @cookbook = cookbook
      @attrs = attrs
    end
    
    def config
      attrs['line_cook'] ||= {
        'script_name' => 'line_cook',
        'recipe_name' => 'line_cook'
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
        :manifest => cookbook.manifest, 
        :attrs => attrs
      )
    end
    
    def build_to(dir)
      unless recipe.closed?
        recipe.evaluate(recipe_name)
        recipe.close
      end
      
      recipe.registry.each_pair do |source, target|
        target = File.join(dir, target)
        yield source, target
      end
    end
  end
end