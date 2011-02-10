require 'linecook/commands/command'
require 'linecook/cookbook'
require 'yaml'

# http://snippets.dzone.com/posts/show/5811
class Hash # :nodoc:
  undef_method :to_yaml
  
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
    
    # ::desc prints a package env
    #
    # Prints the env for the current project directory.  Specifically the
    # cookbook file is loaded and used to determine all resources that are
    # current available.  The full build env for a package can be viewed by
    # specifying the package file as an option.
    #
    # A specific env value can be printed by specifying the key path to it.
    class Env < Command
      config :project_dir, '.', :short => :d        # the project directory
      config :package_file, nil, :short => :p       # the package file
      
      def select(current, *keys)
        keys.each do |key|
          unless current.kind_of?(Hash)
            return nil
          end
          
          current = current[key]
        end
        
        current
      end
      
      def process(*keys)
        cookbook = Linecook::Cookbook.init(project_dir)
        package  = Linecook::Package.load(package_file, cookbook)
        
        env = select(package.env, *keys)
        YAML.dump(env, $stdout)
      end
    end
  end
end