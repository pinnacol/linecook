require 'linecook/commands/command'
require 'linecook/cookbook'

module Linecook
  module Commands
    
    # ::desc prints the cookbook env
    #
    # Print the cookbook env.
    #
    class Env < Command
      config :cookbook_dir, '.', :short => :d       # the cookbook directory
      config :path, nil                             # package path
      
      def process(*keys)
        current = Linecook::Cookbook.init(cookbook_dir).env(path)
        keys.each {|key| current = current[key] if current }
        
        YAML.dump(current, $stdout)
      end
    end
  end
end