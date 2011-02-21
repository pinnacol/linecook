require 'linecook/commands/vbox_command'
require 'tempfile'

module Linecook
  module Commands
    
    # ::desc share a vm folder using sshfs
    #
    # Sets up shared folder using sshfs. By default all hosts configured in
    # config/ssh will share their host:vm remote directory into the vm/host
    # local directory.
    #
    # NOTE: sshfs does not resolve ssh config paths relative to pwd.  Be sure
    # the ssh_config_file uses full paths (even relative paths like
    # ~/.ssh/id_rsa will not work).
    # 
    class Share < VboxCommand
      config :local_dir, 'vm'    # the local share dir
      config :remote_dir, 'vm'   # the remote share dir
      
      def sshfs_path
        @sshfs_path ||= `which sshfs`
      end
      
      def sshfs_installed?
        !sshfs_path.empty?
      end
      
      def share(host)
        share_dir = File.expand_path(host, local_dir)
        FileUtils.mkdir_p(share_dir) unless File.exists?(share_dir)
        
        sh  "umount '#{share_dir}' > /dev/null 2>&1"
        sh! "sshfs -F '#{File.expand_path(ssh_config_file)}' -o ControlMaster=no '#{host}:#{remote_dir}' '#{share_dir}'"
      end
      
      def process(*hosts)
        unless sshfs_installed?
          raise CommandError, "cannot share: sshfs is not installed"
        end
        
        each_host(hosts) do |host|
          share(host)
        end
      end
    end
  end
end