require 'linecook/commands/command'
require 'linecook/cookbook'
require 'linecook/recipe'
require 'yaml'

module Linecook
  module Commands
    
    # ::desc generates a package
    #
    # Generates a package.
    #
    class Package < Command
      config :cookbook_dir, '.', :short => :d       # the cookbook directory
      config :force, false, :short => :f, &c.flag   # force creation
      
      def process(source, target=nil)
        target ||= default_target(source)
        
        if File.exists?(target)
          if force
            FileUtils.rm_r(target)
          else
            raise "already exists: #{target}"
          end
        end
        
        log :create, File.basename(target)
        
        cookbook = Linecook::Cookbook.init(cookbook_dir)
        Linecook::Package.build(source, cookbook).export(target)
      end
      
      def default_target(source)
        source.chomp(File.extname(source))
      end
    end
  end
end