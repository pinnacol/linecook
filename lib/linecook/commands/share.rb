require 'linecook/commands/vbox_command'
require 'tempfile'

module Linecook
  module Commands
    
    # ::desc setup a vm shared folder
    #
    # Sets up a transient shared folder with one or more VirtualBox virtual
    # machines. By default all virtual machines configured in config/ssh will
    # share the specified folder.  The virtual machines must be running for
    # shares to be established.
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
        
        # a persistent socket appears necessary to prevent ssh from hanging
        # after sshfs
        start_ssh_socket(vm_name)
        
        sh  "umount '#{share_dir}' > /dev/null 2>&1"
        sh! "sshfs -F '#{ssh_config_file}' '#{vm_name}:#{remote_dir}' '#{share_dir}'"
      end
      
      def process(*vm_names)
        unless sshfs_installed?
          raise CommandError, "cannot share: sshfs is not installed"
        end
        
        each_vm_name(vm_names) do |vm_name|
          share(vm_name)
        end
      end
      
      private
      
      REWRITE_FIELDS = %w{IdentityFile ControlPath}
      
      def rewrite_ssh_configs(str)
        REWRITE_FIELDS.each do |field|
          str.gsub!(/^#{field}\s*(.*)$/) do |match|
            "#{field} #{File.expand_path($1)}"
          end
        end
        
        str
      end
      
      alias original_ssh_config_file ssh_config_file
      
      def ssh_config_file
        @full_path_ssh_config_file ||= begin
          @full_path_ssh_config_tempfile = Tempfile.new('full_path_ssh_config_file')
          @full_path_ssh_config_tempfile << rewrite_ssh_configs(File.read(original_ssh_config_file))
          @full_path_ssh_config_tempfile.close
          @full_path_ssh_config_tempfile.path
        end
      end
    end
  end
end