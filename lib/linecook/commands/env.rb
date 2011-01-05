require 'linecook/commands/command'
require 'linecook/cookbook'

module Linecook
  module Commands
    
    # ::desc [keys...]
    # Print the cookbook env.
    #
    class Env < Command
      config :cookbook_dir, '.', :short => :d       # the cookbook directory
      config :uri, nil                              # package uri
      
      def process(*keys)
        current = Linecook::Cookbook.init(cookbook_dir).env(uri)
        keys.each {|key| current = current[key] if current }
        
        YAML.dump(current, $stdout)
      end
    end
  end
end