require 'linecook/commands/helper'
require 'linecook/commands/package'
require 'yaml'

module Linecook
  module Commands
    
    # ::desc build a project
    #
    # Builds all packages and helpers in a project, as needed.
    #
    class Build < Command
      config :force, false, :short => :f, &c.flag # force creation
      config :helpers_dir, 'helpers'
      config :packages_dir, 'packages'
      
      def glob_helpers(project_dir)
        helpers_dir = File.expand_path(self.helpers_dir, project_dir)
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
      
      def glob_packages(project_dir)
        packages_dir = File.expand_path(self.packages_dir, project_dir)
        
        Dir.glob("#{packages_dir}/*.yml").collect do |source|
          [source, source.chomp('.yml')]
        end
      end
      
      def process(project_dir='.')
        project_dir = File.expand_path(project_dir)
        
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
        
        packages = glob_packages(project_dir)
        packages.collect! {|(source, target)| package.process(source, target) }
        packages
      end
    end
  end
end