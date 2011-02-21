require 'linecook/commands/vbox_command'
require 'tempfile'

module Linecook
  module Commands
    
    # ::desc share a vm folder using sshfs
    #
    # Sets up shared folder using sshfs. By default all virtual machines
    # configured in config/ssh will share the host:vm remote directory into
    # the vm/host local directory.  The virtual machines must be running for
    # shares to be established.
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
      
      def share(vm_name)
        share_dir = File.expand_path(vm_name, local_dir)
        FileUtils.mkdir_p(share_dir) unless File.exists?(share_dir)
        
        sh  "umount '#{share_dir}' > /dev/null 2>&1"
        sh! "sshfs -F '#{File.expand_path(ssh_config_file)}' -o ControlMaster=no '#{vm_name}:#{remote_dir}' '#{share_dir}'"
      end
      
      def process(*vm_names)
        unless sshfs_installed?
          raise CommandError, "cannot share: sshfs is not installed"
        end
        
        each_vm_name(vm_names) do |vm_name|
          share(vm_name)
        end
      end
    end
  end
end