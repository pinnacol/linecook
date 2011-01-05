require 'linecook/commands/command'
require 'linecook/cookbook'
require 'linecook/recipe'
require 'yaml'

module Linecook
  module Commands
    
    # ::name scripts
    # ::desc patterns...
    #
    # Generates scripts that match the input patterns (by default all).
    #
    class Scripts < Command
      config :cookbook_dir, '.', :short => :d       # the cookbook directory
      config :force, false, :short => :f, &c.flag   # force creation
      
      def call(argv)
        argv << '.*' if argv.empty?
        filters  = argv.collect {|arg| Regexp.new("^#{arg}$", Regexp::IGNORECASE) }
        cookbook = Linecook::Cookbook.init(cookbook_dir)
        
        each_script(cookbook_dir) do |source, target, name|
          next unless filters.any? {|filter| filter =~ name }
          
          if File.exists?(target)
            if force
              FileUtils.rm_r(target)
            else
              raise "already exists: #{target}"
            end
          end
          
          log :create, name
          
          env = cookbook.env(source)
          Linecook::Recipe.build(env).export File.join(cookbook.dir, 'scripts', name)
        end
      end
      
      def each_script(dir)
        scripts_dir = File.expand_path('scripts', dir)

        Dir.glob("#{scripts_dir}/*.yml").each do |source|
          name   = File.basename(source).chomp('.yml')
          target = File.join(scripts_dir, name)

          yield source, target, name
        end
      end
    end
  end
end