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
      config :name, 'vm'         # the share name
      config :remote_dir, 'vm'   # the remote share dir
      
      def sshfs_path
        @sshfs_path ||= `which sshfs`
      end
      
      def sshfs?
        !sshfs_path.empty?
      end
      
      REWRITE_FIELDS = %w{IdentityFile ControlPath}
      def rewrite_ssh_configs(str)
        REWRITE_FIELDS.each do |field|
          str.gsub!(/^#{field}\s*(.*)$/) do |match|
            "#{field} #{File.expand_path($1)}"
          end
        end
        
        str
      end
      
      def full_path_ssh_config_file
        @full_path_ssh_config_file ||= begin
          @full_path_ssh_config_tempfile = Tempfile.new('full_path_ssh_config_file')
          @full_path_ssh_config_tempfile << rewrite_ssh_configs(File.read(ssh_config_file))
          @full_path_ssh_config_tempfile.close
          @full_path_ssh_config_tempfile.path
        end
      end
      
      def share_sshfs(vm_name, name, local_dir, remote_dir)
        share_dir = "#{local_dir}/#{vm_name}"
        FileUtils.mkdir_p(share_dir) unless File.exists?(share_dir)
        sh! "sshfs -F '#{full_path_ssh_config_file}' '#{vm_name}:#{remote_dir}' '#{share_dir}'"
      end
      
      def process(local_dir='vm', *vm_names)
        local_dir = File.expand_path(local_dir)
        
        each_vm_name(vm_names) do |vm_name|
          if sshfs?
            share_sshfs(vm_name, name, local_dir, remote_dir)
          else
            share(vm_name, name, local_dir, remote_dir)
          end
        end
      end
    end
  end
end