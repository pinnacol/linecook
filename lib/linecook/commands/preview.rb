require 'linecook/commands/command'
require 'linecook/cookbook'
require 'linecook/package'
require 'yaml'

module Linecook
  module Commands
    
    # ::desc preview recipe output
    #
    # Evaluates and prints the output of a recipe (ie the resulting script and
    # any associated files). Filters can be applied to examine only parts of
    # the recipe output, for example only files matching a specific pattern:
    #
    #   % linecook preview recipe_name --only pattern
    #
    # By default .zip and .gz files are filtered, both because they are
    # typically big and because they don't print as plain text.
    class Preview < Command
      config :project_dir, '.', :short => :d        # the project directory
      config :package_path, nil, :short => :p       # the package path
      
      config :only, '.' do |filter|                 # an 'only' target filter
        Regexp.new(filter)
      end
      
      config :except, '\.(zip|gz)$' do |filter|     # an 'except' target filter
        Regexp.new(filter)
      end
      
      config :max, 10 ** 4, &c.integer              # max length to display (per file)
      
      def process(*recipes)
        cookbook = Linecook::Cookbook.init(project_dir)
        package  = Linecook::Package.load(package_path, cookbook)
        
        package.config[Linecook::Package::RECIPES_KEY] = recipes
        package.build

        package.registry.keys.sort.each do |name|
          next unless name =~ only && name !~ except
          display(package, name)
        end
      end

      def display(package, name)
        puts "\033[0;34m--[#{name}]\033[0m"
        content = package.content(name, max)
        puts content
        puts '...' if content.length == max
        puts "\033[0;34m--[#{name}]--\033[0m"
      end
    end
  end
end