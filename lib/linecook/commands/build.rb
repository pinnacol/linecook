require 'linecook/commands/helper'
require 'linecook/commands/package'

module Linecook
  module Commands
    
    # :startdoc::desc build a project
    #
    # Builds some or all packages and helpers in a project, as needed.
    #
    class Build < Command
      config :project_dir, '.', :short => :d              # the project directory
      config :load_path, [], :short => :I, &c.list        # set load paths
      config :force, false, :short => :f, &c.flag         # force creation
      config :quiet, false, &c.flag                       # silence output
      
      def glob_helpers(project_dir)
        helpers_dir = File.expand_path('helpers', project_dir)
        sources = {}
        helpers = []
        
        Dir.glob("#{helpers_dir}/*/**/*").each do |source_file|
          next if File.directory?(source_file)
          (sources[File.dirname(source_file)] ||= []) << source_file
        end
        
        sources.each_pair do |dir, source_files|
          name = dir[(helpers_dir.length + 1)..-1]
          helpers << [name, source_files]
        end
        
        helpers.sort_by {|name, source_files| name }
      end
      
      def glob_package_files(package_names)
        if package_names.empty?
          pattern = File.expand_path('packages/*.yml', project_dir)
          Dir.glob(pattern).select {|path| File.file?(path) }
        else
          package_names.collect do |package_name|
            File.expand_path("packages/#{package_name}.yml", project_dir)
          end
        end
      end
      
      def process(*package_names)
        load_path.each do |path|
          $:.unshift(path)
        end
        
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
          :quiet => quiet
        )
        
        glob_package_files(package_names).collect do |package_file|
          package.process(package_file)
        end
      end
    end
  end
end