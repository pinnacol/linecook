require 'linecook/commands/command'
require 'linecook/cookbook'
require 'linecook/script'

module Linecook
  module Commands
    
    # ::desc patterns...
    #
    # Generates scripts that match the input patterns (by default all).
    #
    class Scripts < Command
      config :cookbook_dir, '.'     # the cookbook directory
      
      def call(argv)
        argv << '.*' if argv.empty?
        filters  = argv.collect {|arg| Regexp.new("^#{arg}$", Regexp::IGNORECASE) }
        cookbook = Linecook::Cookbook.init(cookbook_dir)
        
        cookbook.each_script do |source, target, name|
          next unless filters.any? {|filter| filter =~ name }
          log :create, name
          
          script = Linecook::Script.new(cookbook.manifest, YAML.load_file(source))
          script.build_to(target, :force => true)
        end
      end
    end
  end
end