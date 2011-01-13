require 'linecook/commands/command'
require 'linecook/helper'
require 'linecook/utils'

module Linecook
  module Commands
    
    # ::desc generates a helper
    class Helper < Command
      config :cookbook_dir, '.', :short => :d       # the cookbook directory
      config :namespace, nil, :short => :n          # the helper namespace
      config :force, false, :short => :f, &c.flag   # force creation
      
      include Utils
      
      def valid?(const_name)
        const_name =~ /\A(?:::)?[A-Z]\w*(?:::[A-Z]\w*)*\z/
      end
      
      def process(name, *sources)
        name = underscore(name)
        
        const_path = namespace ? File.join(namespace, name) : name
        const_name = camelize(const_path)
        
        unless valid?(const_name)
          raise "invalid constant name: #{const_name.inspect}"
        end
        
        sources = default_sources(name) if sources.empty?
        target  = File.expand_path(File.join('lib', "#{const_path}.rb"), cookbook_dir)
        
        if sources.empty?
          raise CommandError, "no sources specified (and none could be found)"
        end
        
        if File.exists?(target) && !force
          raise CommandError, "already exists: #{target}"
        end
        
        log :create, const_name
        
        helper = Linecook::Helper.new(const_name, sources)
        content = helper.build

        target_dir = File.dirname(target)
        unless File.exists?(target_dir)
          FileUtils.mkdir_p(target_dir) 
        end

        File.open(target, 'w') {|io| io << content }
      end
      
      def default_sources(name)
        Dir.glob File.join(cookbook_dir, 'helpers', name, '*')
      end
    end
  end
end