require 'linecook/commands/command'
require 'linecook/cookbook'
require 'linecook/package'
require 'yaml'

module Linecook
  module Commands
    
    # ::desc generates a package
    #
    # Generates a package from a package file.  Package files are YAML files
    # that specify a package env.  The env specifies recipes to build into the
    # package, and the attributes to build them with.
    #
    # If a cookbook file is present in the project_dir then it will be used to
    # resolve resources available to the package.  See the env command to
    # interrogate a package env.
    class Package < Command
      config :project_dir, '.', :short => :d        # the project directory
      config :force, false, :short => :f, &c.flag   # force creation
      
      def process(package_file, package_dir=nil)
        package_dir ||= default_package_dir(package_file)
        package  = Linecook::Package.init(package_file, project_dir)
        
        if force || !File.exists?(package_dir)
          log :create, File.basename(package_dir)
          package.build
          package.export(package_dir)
        end
        
        package_dir
      end
      
      def default_package_dir(package_file)
        package_file.chomp(File.extname(package_file))
      end
    end
  end
end