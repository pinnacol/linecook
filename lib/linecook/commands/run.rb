require 'linecook/commands/command'
require 'linecook/commands/build'

module Linecook
  module Commands
    
    # :startdoc::desc run packages
    class Run < Command
      RUN_SCRIPT = File.expand_path('../../../../bin/linecook_run', __FILE__)
      SCP_SCRIPT = File.expand_path('../../../../bin/linecook_scp', __FILE__)
      
      config :project_dir, '.', :short => :d                 # the project directory
      config :remote_dir, 'pkg', :short => :D                # the remote package dir
      config :ssh_config_file, 'config/ssh', :short => :F    # the ssh config file
      config :quiet, false, :short => :q, &c.flag            # silence output
      config :transfer, true, &c.switch                      # transfer package (or not)
      config :file, false, &c.flag                           # treat package name as file path
      config :runlist, nil                                   # specify a runlist ('-' for stdnin)
      
      def process(*package_names)
        package_names = glob_package_names(project_dir) if package_names.empty?
        package_dirs  = collect_package_dirs(package_names)
        
        opts = {
          'D' => remote_dir,
          'F' => ssh_config_file
        }
        
        sh! "sh #{SCP_SCRIPT} #{format(opts)} #{package_dirs.join(' ')}" if transfer
        sh! "sh #{RUN_SCRIPT} #{format(opts)} #{package_dirs.join(' ')}#{source(runlist)}"
      end
      
      def source(runlist)
        case runlist
        when nil
          " <<DOC\nrun\ntest\nDOC"
        when '-'
          nil
        else
          " < '#{runlist}'"
        end
      end
      
      def format(opts)
        options = []
        
        opts.each_pair do |key, value|
          options << "-#{key} '#{value}'"
        end
        
        options.sort.join(' ')
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
          "'#{file ? name : guess_package_dir(name)}'"
        end
      end
      
      def guess_package_dir(name)
        File.expand_path("packages/#{name}", project_dir)
      end
    end
  end
end