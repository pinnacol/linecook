require 'linecook/commands/command'
require 'linecook/cookbook'
require 'linecook/package'
require 'yaml'

module Linecook
  module Commands
    
    # ::desc preview recipe output
    class Preview < Command
      config :cookbook_dir, '.', :short => :d       # the cookbook directory
      config :force, false, :short => :f, &c.flag   # force creation
      config :source, nil                           # the package file
      config :filter, '.' do |filter|               # a target filter
        Regexp.new(filter)
      end

      def process(*recipes)
        cookbook = Linecook::Cookbook.init(cookbook_dir)
        package  = Linecook::Package.load(source, cookbook)

        package.config['recipes'] = recipes
        package.build

        package.registry.keys.sort.each do |name|
          next unless name =~ filter
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