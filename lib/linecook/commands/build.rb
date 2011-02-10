require 'linecook/commands/helper'
require 'linecook/commands/package'

module Linecook
  module Commands
    
    # ::desc build a project
    #
    # Builds some or all packages and helpers in a project, as needed.
    #
    class Build < Command
      config :project_dir, '.', :short => :d      # the project directory
      config :force, false, :short => :f, &c.flag # force creation
      
      def glob_helpers(project_dir)
        helpers_dir = File.expand_path('helpers', project_dir)
        sources = {}
        helpers = []
        
        Dir.glob("#{helpers_dir}/*/**/*").each do |source|
          next if File.directory?(source)
          (sources[File.dirname(source)] ||= []) << source
        end
        
        sources.each_pair do |dir, sources|
          name = dir[(helpers_dir.length + 1)..-1]
          helpers << [name, sources]
        end
        
        helpers.sort_by {|name, sources| name }
      end
      
      def glob_package_files(project_dir)
        packages_dir = File.expand_path('packages', project_dir)
        Dir.glob("#{packages_dir}/*.yml")
      end
      
      def process(*package_files)
        helper = Helper.new(
          :project_dir => project_dir, 
          :force => force
        )
        
        helpers = glob_helpers(project_dir)
        helpers.collect! {|(name, sources)| helper.process(name, *sources) }
        
        package = Package.new(
          :project_dir => project_dir,
          :force => force
        )
        
        if package_files.empty?
          package_files = glob_package_files(project_dir)
        end
        
        package_files.collect! {|source| package.process(source) }
      end
    end
  end
end