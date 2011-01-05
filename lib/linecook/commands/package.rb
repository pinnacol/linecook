require 'linecook/commands/command'
require 'linecook/cookbook'
require 'linecook/recipe'
require 'yaml'

module Linecook
  module Commands
    
    # ::desc uri [target]
    #
    # Generates a package.
    #
    class Package < Command
      config :cookbook_dir, '.', :short => :d       # the cookbook directory
      config :force, false, :short => :f, &c.flag   # force creation
      
      def process(uri, target=default_target(uri))
        if File.exists?(target)
          if force
            FileUtils.rm_r(target)
          else
            raise "already exists: #{target}"
          end
        end
        
        log :create, File.basename(target)
        
        env = Linecook::Cookbook.init(cookbook_dir).env(uri)
        Linecook::Recipe.build(env).export(target)
      end
      
      def default_target(uri)
        File.file?(uri) ? uri.chomp(File.extname(uri)) : File.join(cookbook_dir, 'package')
      end
    end
  end
end