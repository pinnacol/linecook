require 'linecook/commands/command'
require 'linecook/commands/build'

module Linecook
  module Commands
    
    # :startdoc::desc run packages
    class Run < Command
      RUN_SCRIPT = File.expand_path('../../../../bin/linecook_run', __FILE__)
      SCP_SCRIPT = File.expand_path('../../../../bin/linecook_scp', __FILE__)
      
      config :project_dir, '.', :short => :d                 # the project directory
      config :remote_dir, 'linecook', :short => :D           # the remote package dir
      config :ssh_config_file, 'config/ssh', :short => :F    # the ssh config file
      config :quiet, false, :short => :q, &c.flag            # silence output
      config :transfer, true, &c.switch                      # transfer package (or not)
      config :remote_scripts, ['run'], 
        :short => :S, 
        :long => :remote_script, &c.list                     # the remote script(s)
      
      def glob_package_dirs(package_names)
        if package_names.empty?
          pattern = File.expand_path('packages/*', project_dir)
          Dir.glob(pattern).select {|path| File.directory?(path) }
        else
          package_names.collect do |package_name|
            File.expand_path("packages/#{package_name}", project_dir)
          end
        end
      end
      
      def process(*package_names)
        package_dirs  = glob_package_dirs(package_names)
        
        unless remote_dir[0] == ?/
          self.remote_dir = "$(pwd)/#{remote_dir}"
          self.remote_dir.chomp!('/')
        end
        
        opts = {
          'D' => remote_dir,
          'F' => ssh_config_file
        }
        
        if transfer
          sh! "sh #{SCP_SCRIPT} #{format(opts)} #{package_dirs.join(' ')}"
        end

        remote_scripts.each do |remote_script|
          script_opts = {'S' => remote_script}.merge(opts)
          sh! "sh #{RUN_SCRIPT} #{format(script_opts)} #{package_dirs.join(' ')}"
        end
      end
      
      def format(opts)
        options = []
        
        opts.each_pair do |key, value|
          options << "-#{key} '#{value}'"
        end
        
        options.sort.join(' ')
      end
    end
  end
end