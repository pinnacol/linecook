require 'linecook/commands/command'
require 'linecook/cookbook'
require 'pp'

module Linecook
  module Commands
    
    # ::name env
    # ::desc [keys...]
    # Print the cookbook env.
    #
    class Env < Command
      config :cookbook_dir, '.', :short => :d       # the cookbook directory
      config :uris, [], &c.list                     # package uris
      
      def call(argv)
        config = Linecook::Cookbook.init(cookbook_dir, *uris).config
        argv = config.keys if argv.empty?
        
        results = {}
        argv.each {|key| results[key] = config[key] }
        
        pp results
      end
    end
  end
end