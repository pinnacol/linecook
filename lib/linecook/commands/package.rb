require 'linecook/commands/command'
require 'linecook/cookbook'
require 'linecook/package'
require 'fileutils'
require 'yaml'

module Linecook
  module Commands
    
    # ::desc generates a package
    #
    # Generates the package specified at
    # 'project_dir/packages/package_name.yml'.  The package file should be a
    # YAML files that specifies a package env.  The full path to package file
    # can be given instead of package name using the --file option.
    #
    # If a cookbook file is present in the project_dir then it will be used to
    # resolve resources available to the package.  See the env command to
    # interrogate a package env.
    class Package < Command
      config :project_dir, '.', :short => :d              # the project directory
      config :force, false, :short => :f, &c.flag         # force creation
      config :quiet, false, &c.flag                       # silence output
      config :file, false, &c.flag                        # treat package name as file path
      
      def process(package_name, package_dir=nil)
        package_file = file ? package_name : guess_package_file(package_name)
        package_dir ||= default_package_dir(package_file)
        package_dir = File.expand_path(package_dir)
        package = Linecook::Package.init(package_file, project_dir)
        
        dependencies = package_dependencies(package) + [package_file]
        if force || !FileUtils.uptodate?(package_dir, dependencies)
          package.build
          package.export(package_dir)
          $stdout.puts package_dir unless quiet
        end
        
        package_dir
      end
      
      def guess_package_file(name)
        File.expand_path("packages/#{name}.yml", project_dir)
      end
      
      def package_dependencies(package)
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