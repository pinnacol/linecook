require 'linecook/commands/command'
require 'linecook/cookbook'
require 'linecook/helper'

module Linecook
  module Commands
    
    # ::name helpers
    # ::desc patterns...
    #
    # Generates helpers that match the input patterns (by default all,
    # helpers).
    #
    class Helpers < Command
      config :cookbook_dir, '.'     # the cookbook directory
      config :force, false, :short => :f, &c.flag   # force creation
      
      def call(argv)
        argv << '.*' if argv.empty?
        filters  = argv.collect {|arg| Regexp.new("^#{arg}$", Regexp::IGNORECASE) }
        cookbook = Linecook::Cookbook.init(cookbook_dir)
        
        cookbook.each_helper do |sources, target, const_name|
          next unless filters.any? {|filter| filter =~ const_name }
          
          if File.exists?(target) && !force
            raise "already exists: #{target}"
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
      end
    end
  end
end