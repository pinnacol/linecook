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
      config :only, '.' do |filter|                 # an 'only' target filter
        Regexp.new(filter)
      end
      config :except, '\.zip$' do |filter|          # an 'except' target filter
        Regexp.new(filter)
      end
      config :max, 10 ** 4, &c.integer              # max length to read
      
      def process(*recipes)
        cookbook = Linecook::Cookbook.init(cookbook_dir)
        package  = Linecook::Package.load(source, cookbook)

        package.config['recipes'] = recipes
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