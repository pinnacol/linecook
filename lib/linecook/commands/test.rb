require 'linecook/commands/command'
require 'linecook/commands/build'

module Linecook
  module Commands
    
    # ::desc 
    class Test < Command
      config :project_dir, '.', :short => :d              # the project directory
      config :remote_test_dir, 'vm/test'
      # config :default_host, 'vbox'
      # config :keep_outputs, false
      config :shell, 'sh'
      config :quiet, false, &c.flag                       # silence output
      
      SCRIPT = File.expand_path('../../../../bin/linecook_test', __FILE__)
      
      def process(*package_names)
        packages = package_names.empty? ? glob_package_dirs(project_dir) : collect_package_dirs(package_names)
        
        ENV['REMOTE_TEST_DIR'] = remote_test_dir
        sh! "#{shell} #{SCRIPT} '#{project_dir}' '#{packages.join("' '")}'"
      end
      
      def glob_package_dirs(project_dir)
        packages_dir = File.expand_path('packages', project_dir)
        package_dirs = Dir.glob("#{packages_dir}/*")
        package_dirs.select {|dir| File.directory?(dir) }
      end
      
      def collect_package_dirs(package_names)
        package_names.collect do |name|
          guess_package_dir(name)
        end
      end
      
      def guess_package_dir(name)
        File.expand_path("packages/#{name}", project_dir)
      end
    end
  end
end