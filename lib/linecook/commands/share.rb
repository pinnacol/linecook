require 'linecook/commands/vbox_command'

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
      config :name, 'vm'             # the share name
      config :remote_dir, '~/vm'    # the remote share dir
      
      def share(local_dir, vm_name)
        ssh vm_name, "sudo umount '#{remote_dir}' > /dev/null 2>&1"
        sh "VBoxManage sharedfolder remove '#{vm_name}' --name '#{name}' --transient > /dev/null 2>&1"
        sh! "VBoxManage sharedfolder add '#{vm_name}' --name '#{name}' --hostpath '#{local_dir}' --transient"
        ssh! vm_name, "sudo mount -t vboxsf -o uid=1000,gid=100 '#{name}' '#{remote_dir}'"
      end
      
      def process(local_dir='vm', *vm_names)
        local_dir = File.expand_path(local_dir)
        
        each_vm_name(vm_names) do |vm_name|
          share(local_dir, vm_name)
        end
      end
    end
  end
end