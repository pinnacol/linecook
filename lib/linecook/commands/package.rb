require 'linecook/commands/command'
require 'linecook/cookbook'
require 'linecook/package'
require 'fileutils'
require 'yaml'

module Linecook
  module Commands
    
    # ::desc generates a package
    #
    # Generates a package from a package file.  Package files are YAML files
    # that specify a package env.  A package name can be given instead of a
    # package file; in that case the actual package file should be located at
    # 'project_dir/packages/name.yml'.
    #
    # If a cookbook file is present in the project_dir then it will be used to
    # resolve resources available to the package.  See the env command to
    # interrogate a package env.
    class Package < Command
      config :project_dir, '.', :short => :d              # the project directory
      config :force, false, :short => :f, &c.flag         # force creation
      config :quiet, false, &c.flag                       # silence output
      config :guess_name, false, :long => :name, &c.flag  # specify a package name
      
      def process(package_file, package_dir=nil)
        package_file = guess_package_file(package_file) if guess_name
        
        package_dir ||= default_package_dir(package_file)
        package_dir = File.expand_path(package_dir)
        package = Linecook::Package.init(package_file, project_dir)
        
        if force || !FileUtils.uptodate?(package_dir, dependencies(package))
          package.build
          package.export(package_dir)
          $stdout.puts package_dir unless quiet
        end
        
        package_dir
      end
      
      def guess_package_file(name)
        File.expand_path("packages/#{name}.yml", project_dir)
      end
      
      def dependencies(package)
        dependencies = []
        package.manifest.values.collect do |resources|
          dependencies.concat resources.values
        end
        
        $LOAD_PATH.each do |path|
          dependencies.concat Dir.glob("#{path}/**/*.rb")
        end
        dependencies
      end
      
      def default_package_dir(package_file)
        package_file.chomp(File.extname(package_file))
      end
    end
  end
end