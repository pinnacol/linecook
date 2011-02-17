require 'linecook/commands/command'
require 'linecook/commands/build'

module Linecook
  module Commands
    
    # ::desc 
    class Test < Command
      TEST_SCRIPT = File.expand_path('../../../../bin/linecook_test', __FILE__)
      
      config :project_dir, '.', :short => :d              # the project directory
      config :remote_dir, 'vm'
      config :ssh_config_file, 'config/ssh'
      config :quiet, false, &c.flag                       # silence output
      config :file, false, &c.flag                        # treat package name as file path
      
      def process(*package_names)
        package_names = glob_package_names(project_dir) if package_names.empty?
        package_dirs  = collect_package_dirs(package_names)
        
        sh! "sh #{TEST_SCRIPT} -d'#{remote_dir}' '#{package_dirs.join("' '")}'"
      end
      
      def glob_package_names(project_dir)
        packages_dir = File.expand_path('packages', project_dir)
        package_dirs = Dir.glob("#{packages_dir}/*").select {|dir| File.directory?(dir) }
        
        unless file
          package_dirs.collect! do |path|
            File.basename(path)
          end
        end
        
        package_dirs
      end
      
      def collect_package_dirs(package_names)
        package_names.collect do |name|
          file ? name : guess_package_dir(name)
        end
      end
      
      def guess_package_dir(name)
        File.expand_path("packages/#{name}", project_dir)
      end
    end
  end
end