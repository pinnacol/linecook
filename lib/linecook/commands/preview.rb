require 'linecook/commands/command'
require 'linecook/cookbook'
require 'linecook/package'
require 'yaml'

module Linecook
  module Commands
    
    # ::desc generates a package
    #
    # Generates a package.
    #
    class Preview < Command
      config :cookbook_dir, '.', :short => :d       # the cookbook directory
      config :force, false, :short => :f, &c.flag   # force creation
      
      def process(recipe_name, source=nil)
        cookbook = Linecook::Cookbook.init(cookbook_dir)
        package  = Linecook::Package.load(source, cookbook)
        
        package.recipes.clear
        package.recipes[recipe_name] = recipe_name
        
        package.build
        display(package, recipe_name)
        
        package.registry.keys.sort.each do |name|
          next if name == recipe_name
          display(package, name)
        end
      end
      
      def display(package, name)
        puts "\033[0;34m--[#{name}]\033[0m"
        puts package.content(name)
        puts "\033[0;34m--[#{name}]--\033[0m"
        puts package.content(name)
      end
    end
  end
end