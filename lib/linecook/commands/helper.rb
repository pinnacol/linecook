require 'linecook/commands/command'
require 'linecook/helper'
require 'linecook/utils'

module Linecook
  module Commands
    
    # ::desc generates a helper module
    #
    # Generates the specified helper module from a set of source files.  Each
    # source file becomes a method in the module, named after the source file
    # itself.
    #
    # The helper module will be generated under the lib directory in a file
    # corresponding to const_name (which can also be a constant path).  By
    # default, all files under the corresponding helpers directory will be
    # used as sources.  For example these are equivalent and produce the
    # Const::Name module in 'lib/const/name.rb':
    #
    #   % linecook helpers Const::Name
    #   % linecook helpers const/name
    #   % linecook helpers const/name helpers/const/name/*
    #
    class Helper < Command
      config :project_dir, '.', :short => :d        # the project directory
      config :force, false, :short => :f, &c.flag   # force creation
      
      include Utils
      
      def valid?(const_name)
        const_name =~ /\A(?:::)?[A-Z]\w*(?:::[A-Z]\w*)*\z/
      end
      
      def process(const_name, *sources)
        const_path = underscore(const_name)
        const_name = camelize(const_path)
        
        unless valid?(const_name)
          raise "invalid constant name: #{const_name.inspect}"
        end
        
        sources = default_sources(const_path) if sources.empty?
        target  = File.expand_path(File.join('lib', "#{const_path}.rb"), project_dir)
        
        if sources.empty?
          raise CommandError, "no sources specified (and none found under 'helpers/#{const_path}')"
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
      
      def default_sources(const_path)
        Dir.glob File.join(project_dir, 'helpers', const_path, '*')
      end
    end
  end
end