require 'linecook/commands/command'
require 'linecook/cookbook'
require 'yaml'

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
      
      # :stopdoc:
      # Evaluate to replace the to_yaml function on Hash so that it will
      # serialize keys in order.  Evaluate the OFF code to turn this hack off
      # (and thereby ease up on the code pollution)
      #
      # Modified from: http://snippets.dzone.com/posts/show/5811 Original
      # func: /usr/lib/ruby/1.8/yaml/rubytypes.rb
      ORIGINAL_TO_YAML = 'linecook_original_to_yaml'
      SORTED_HASH_ON_LINE = __LINE__ + 1
      SORTED_HASH_ON = %{
      class Hash
        unless instance_methods.include?('#{ORIGINAL_TO_YAML}')
          alias #{ORIGINAL_TO_YAML} to_yaml
          undef_method :to_yaml
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
      end}
      
      SORTED_HASH_OFF_LINE = __LINE__ + 1
      SORTED_HASH_OFF = %{
      class Hash
        if instance_methods.include?('#{ORIGINAL_TO_YAML}')
          undef_method :to_yaml
          alias to_yaml #{ORIGINAL_TO_YAML}
          undef_method :#{ORIGINAL_TO_YAML}
        end
      end}
      # :startdoc:
      
      def select(current, *keys)
        keys.each do |key|
          unless current.kind_of?(Hash)
            return nil
          end
          
          current = current[key]
        end
        
        current
      end
      
      # Serializes the env to the target as YAML.  Ensures hashes are
      # serialized with their keys sorted by their to_s value.
      def serialize(env, target="")
        begin
          eval SORTED_HASH_ON, TOPLEVEL_BINDING, __FILE__, SORTED_HASH_ON_LINE
          YAML.dump(env, target)
        ensure
          eval SORTED_HASH_OFF, TOPLEVEL_BINDING, __FILE__, SORTED_HASH_OFF_LINE
        end
      end
      
      def process(*keys)
        package  = Linecook::Package.init(package_file, project_dir)
        env = select(package.env, *keys)
        serialize(env, $stdout)
      end
    end
  end
end