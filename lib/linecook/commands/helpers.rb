require 'linecook/commands/command'
require 'linecook/cookbook'
require 'linecook/helper'

module Linecook
  module Commands
    
    # ::desc 
    class Helpers < Command
      config :cookbook_dir, '.'     # the cookbook directory
      
      def call(argv)
        argv << '.*' if argv.empty?
        filters  = argv.collect {|arg| Regexp.new("^#{arg}$", Regexp::IGNORECASE) }
        cookbook = Linecook::Cookbook.init(cookbook_dir)
        
        cookbook.each_helper do |sources, target, const_name|
          next unless filters.any? {|filter| filter =~ const_name }
          log :create, const_name
          
          helper = Linecook::Helper.new(const_name, sources)
          helper.build_to(target, :force => true)
        end
      end
    end
  end
end