require 'linecook/commands/command'
require 'linecook/commands/build'

module Linecook
  module Commands
    
    # ::desc 
    class Run < Command
      RUN_SCRIPT = File.expand_path('../../../../bin/linecook_run', __FILE__)
      
      config :project_dir, '.', :short => :d                 # the project directory
      config :remote_dir, 'vm', :short => :D
      config :ssh_config_file, 'config/ssh', :short => :F
      config :quiet, false, :short => :q, &c.flag            # silence output
      config :verbose, false, :short => :v, &c.flag          # verbose output
      config :xtrace, false, :short => :x, &c.flag           # xtrace output
      config :file, false, &c.flag                           # treat package name as file path
      config :run_script, 'run', :short => :r
      config :test_script, 'test', :short => :t
      
      def xtrace?
        xtrace
      end
      
      def verbose?
        verbose && !xtrace?
      end
      
      def quiet?
        quiet && !verbose?
      end
      
      def process(*package_names)
        shell_opts = {
          'v' => verbose?,
          'x' => xtrace?
        }
        
        run_opts = {
          'D' => remote_dir,
          's' => ssh_opts,
          'c' => scp_opts,
          'F' => ssh_config_file,
          'r' => run_script,
          't' => test_script
        }
        
        package_names = glob_package_names(project_dir) if package_names.empty?
        package_dirs  = collect_package_dirs(package_names)
        
        cmd = ["sh", format(shell_opts), RUN_SCRIPT, format(run_opts)] + package_dirs
        cmd.delete_if {|arg| arg.empty? }
        
        sh! cmd.join(' ')
      end
      
      def format(opts)
        options = []
        
        opts.keys.sort.collect do |key|
          value = opts[key]
          
          case value
          when true
            options << "-#{key}"
          when false
            options << "+#{key}"
          else
            options << "-#{key} '#{value}'"
          end
        end
        
        options.join(' ')
      end
      
      def ssh_opts
        quiet? ? '-q -T' : ''
      end
      
      def scp_opts
        quiet? ? '-q' : ''
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