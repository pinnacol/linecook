require 'linecook/commands/command'
require 'linecook/cookbook'
require 'yaml'

# http://snippets.dzone.com/posts/show/5811
class Hash
  # Replacing the to_yaml function so it'll serialize hashes sorted (by their keys)
  #
  # Original function is in /usr/lib/ruby/1.8/yaml/rubytypes.rb
  def to_yaml( opts = {} )
    YAML::quick_emit( object_id, opts ) do |out|
      out.map( taguri, to_yaml_style ) do |map|
        sort.each do |k, v|
          map.add( k, v )
        end
      end
    end
  end
end

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
        cookbook = Linecook::Cookbook.init(cookbook_dir)
        package  = Linecook::Package.load(path, cookbook)
        
        current = package.env
        keys.each {|key| current = current[key] if current }
        
        YAML.dump(current, $stdout)
      end
    end
  end
end