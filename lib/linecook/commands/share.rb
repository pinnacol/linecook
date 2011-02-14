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
      config :name, 'vm'         # the share name
      config :remote_dir, '~/vm' # the remote share dir
      
      def process(local_dir='vm', *vm_names)
        local_dir = File.expand_path(local_dir)
        
        each_vm_name(vm_names) do |vm_name|
          share(vm_name, name, local_dir, remote_dir)
        end
      end
    end
  end
end