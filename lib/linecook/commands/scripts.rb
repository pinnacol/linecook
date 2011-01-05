require 'linecook/commands/command'
require 'linecook/cookbook'
require 'linecook/recipe'
require 'yaml'

module Linecook
  module Commands
    
    # ::desc patterns...
    #
    # Generates scripts that match the input patterns (by default all).
    #
    class Scripts < Command
      config :cookbook_dir, '.'     # the cookbook directory
      config :force, false, :short => :f, &c.flag   # force creation
      def call(argv)
        argv << '.*' if argv.empty?
        filters  = argv.collect {|arg| Regexp.new("^#{arg}$", Regexp::IGNORECASE) }
        cookbook = Linecook::Cookbook.init(cookbook_dir)
        
        cookbook.each_script do |source, target, name|
          next unless filters.any? {|filter| filter =~ name }
          
          if File.exists?(target)
            if force
              FileUtils.rm_r(target)
            else
              raise "already exists: #{target}"
            end
          end
          
          log :create, name
          
          env = YAML.load_file(source)
          config = env['linecook'] ||= {} 
          config['manifest'] = cookbook.manifest
          Linecook::Recipe.build(env).export File.join(cookbook.dir, 'scripts', name)
        end
      end
    end
  end
end