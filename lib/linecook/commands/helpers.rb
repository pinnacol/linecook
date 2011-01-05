require 'linecook/commands/command'
require 'linecook/helper'

module Linecook
  module Commands
    
    # ::desc patterns...
    #
    # Generates helpers that match the input patterns (by default all,
    # helpers).
    #
    class Helpers < Command
      config :cookbook_dir, '.', :short => :d       # the cookbook directory
      config :namespace, 'linebook', :short => :n   # the helper namespace
      config :force, false, :short => :f, &c.flag   # force creation
      
      include Utils
      
      def call(argv)
        argv << '.*' if argv.empty?
        filters  = argv.collect {|arg| Regexp.new("^#{arg}$", Regexp::IGNORECASE) }
        
        each_helper(cookbook_dir) do |sources, target, const_name|
          next unless filters.any? {|filter| filter =~ const_name }
          
          if File.exists?(target) && !force
            raise "already exists: #{target}"
          end
          
          log :create, const_name
          
          helper = Helper.new(const_name, sources)
          content = helper.build

          target_dir = File.dirname(target)
          unless File.exists?(target_dir)
            FileUtils.mkdir_p(target_dir) 
          end

          File.open(target, 'w') {|io| io << content }
        end
      end
      
      def each_helper(dir)
        helpers_dir = File.expand_path('helpers', dir)
        lib_dir = File.expand_path('lib', dir)

        sources = {}
        Dir.glob("#{helpers_dir}/**/*").each do |source|
          next if File.directory?(source)
          (sources[File.dirname(source)] ||= []) << source
        end

        sources.each_pair do |dir, sources|
          name = dir[(helpers_dir.length+1)..-1]
          const_path = name ? File.join(namespace, name) : namespace

          target  = File.join(lib_dir, "#{const_path}.rb")
          sources = sources + [dir]

          yield sources, target, Utils.camelize(const_path)
        end
      end
    end
  end
end