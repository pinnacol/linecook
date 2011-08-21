require 'linecook/command'
require 'linecook/command_utils'

module Linecook
  module Commands

    # :startdoc::desc run packages
    #
    # Runs packages on remote hosts by transfering a package directory using
    # scp, and then executing one or more scripts via ssh.  Run is configured
    # using an ssh config file, which should contain all necessary ssh
    # options.
    #
    # Packages are transfered to hosts based on the basename of the package,
    # hence 'path/to/abox' will run on the 'abox' host as configured in the
    # ssh config file.
    #
    class Run < Command
      include CommandUtils

      RUN_SCRIPT = File.expand_path('../../../../bin/linecook_run', __FILE__)
      SCP_SCRIPT = File.expand_path('../../../../bin/linecook_scp', __FILE__)

      config :remote_dir, 'linecook'        # -D : the remote package dir
      config :remote_scripts, ['run']       # -S : the remote script(s)
      config :ssh_config_file, 'config/ssh' # -F : the ssh config file
      config :scp, true                     # transfer package or not

      def full_path_to_remote_dir
        (remote_dir[0] == ?/ ? remote_dir : "$(pwd)/#{remote_dir}").chomp('/')
      end

      def process(*package_dirs)
        opts = {
          'D' => full_path_to_remote_dir,
          'F' => ssh_config_file
        }

        if scp
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