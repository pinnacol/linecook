require 'linecook/commands/helper'
require 'linecook/commands/package'

module Linecook
  module Commands
    
    # ::desc build a project
    #
    # Builds some or all packages and helpers in a project, as needed.
    #
    class Build < Command
      config :project_dir, '.', :short => :d              # the project directory
      config :force, false, :short => :f, &c.flag         # force creation
      config :quiet, false, &c.flag                       # silence output
      config :file, false, &c.flag                        # treat package name as file path
      
      def glob_helpers(project_dir)
        helpers_dir = File.expand_path('helpers', project_dir)
        sources = {}
        helpers = []
        
        Dir.glob("#{helpers_dir}/*/**/*").each do |source|
          if File.directory?(source)
            sources[source] ||= []
          else
            (sources[File.dirname(source)] ||= []) << source
          end
        end
        
        sources.each_pair do |dir, sources|
          name = dir[(helpers_dir.length + 1)..-1]
          helpers << [name, sources]
        end
        
        helpers.sort_by {|name, sources| name }
      end
      
      def glob_package_names(project_dir)
        packages_dir  = File.expand_path('packages', project_dir)
        package_files = Dir.glob("#{packages_dir}/*.yml")
        
        unless file
          package_files.collect! do |path|
            File.basename(path).chomp('.yml')
          end
        end
        
        package_files
      end
      
      def process(*package_names)
        helper = Helper.new(
          :project_dir => project_dir, 
          :force => force,
          :quiet => true
        )
        
        helpers = glob_helpers(project_dir)
        helpers.each do |(name, sources)|
          helper.process(name, *sources)
        end
        
        package = Package.new(
          :project_dir => project_dir,
          :force => force,
          :quiet => quiet,
          :file => file
        )
        
        if package_names.empty?
          package_names = glob_package_names(project_dir)
        end
        
        package_names.collect! do |package_name|
          package.process(package_name)
        end
      end
    end
  end
end