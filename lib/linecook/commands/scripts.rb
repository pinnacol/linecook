require 'linecook/commands/command'
require 'linecook/cookbook'
require 'linecook/recipe'
require 'yaml'

module Linecook
  module Commands
    
    # ::desc patterns...
    #
    # Generates scripts that match the input patterns (by default all).
    #
    class Scripts < Command
      config :cookbook_dir, '.'     # the cookbook directory
      
      def call(argv)
        argv << '.*' if argv.empty?
        filters  = argv.collect {|arg| Regexp.new("^#{arg}$", Regexp::IGNORECASE) }
        cookbook = Linecook::Cookbook.init(cookbook_dir)
        
        cookbook.each_script do |source, target, name|
          next unless filters.any? {|filter| filter =~ name }
          
          if File.exists?(target)
            if force
              FileUtils.rm(target)
            else
              raise "already exists: #{target}"
            end
          end
          
          log :create, name
          
          registry = Linecook::Recipe.build(cookbook.manifest, YAML.load_file(source))
          registry.each_pair do |source, target|
            target = File.join(cookbook.dir, 'scripts', name, target)

            target_dir = File.dirname(target)
            FileUtils.mkdir_p(target_dir) unless File.exists?(target_dir)

            FileUtils.cp(source, target)
          end
        end
      end
    end
  end
end