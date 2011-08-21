require 'linecook/commands/virtual_box_command'

module Linecook
  module Commands
    
    # :startdoc::desc start a vm
    #
    # Starts one or more VirtualBox virtual machines, and resets to a snapshot
    # if provided. By default all virtual machines configured in config/ssh
    # will be reset and started in this way.
    class Start < VirtualBoxCommand
      config :type, 'headless'          # vm type (headless|gui)
      config :snapshot, ''              # start snapshot
      config :use_master_socket, false  # -m, --master-socket : use a master socket
      
      def process(*hosts)
        vm_names = resolve_vm_names(hosts)
        each_vm_name(vm_names) do |vm_name|
          if running?(vm_name)
            stop(vm_name)
            sleep 0.5
          end
          
          unless snapshot.empty?
            restore(vm_name, snapshot)
          end
          
          start(vm_name, type)
          start_ssh_socket(vm_name) if use_master_socket
        end
      end
    end
  end
end