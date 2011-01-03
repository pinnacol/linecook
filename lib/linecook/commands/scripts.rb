require 'linecook/commands/command'
require 'linecook/cookbook'
require 'linecook/script'
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
          
          context = YAML.load_file(source)
          script  = Linecook::Script.new(context)
          script.manifest.merge!(cookbook.manifest)
          
          script.build
          script.close
          script.registry.each_pair do |source, relative_path|
            target = File.join(cookbook.dir, 'scripts', name, relative_path)

            target_dir = File.dirname(target)
            FileUtils.mkdir_p(target_dir) unless File.exists?(target_dir)

            FileUtils.cp(source, target)
          end
        end
      end
    end
  end
end