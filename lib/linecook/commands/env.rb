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
        keys.sort_by do |k|
          k.to_s
        end.each do |k|
          map.add( k, fetch(k) )
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
      
      def serialize(env, target="")
        YAML.dump(env, target)
      end
      
      def process(*keys)
        package  = Linecook::Package.init(package_file, project_dir)
        env = select(package.env, *keys)
        serialize(env, $stdout)
      end
    end
  end
end