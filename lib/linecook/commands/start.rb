require 'linecook/commands/vbox_command'

module Linecook
  module Commands
    
    # ::desc start a vm
    #
    # Starts one or more VirtualBox virtual machines, and resets to a snapshot
    # if provided. By default all virtual machines configured in config/ssh
    # will be reset and started in this way.
    class Start < VboxCommand
      config :type, 'headless'             # vm type (headless|gui)
      config :snapshot, '', :short => :s   # start snapshot
      
      def process(*vm_names)
        each_vm_name(vm_names) do |vm_name|
          unless snapshot.empty?
            stop(vm_name) if running?(vm_name)
            reset(vm_name, snapshot)
          end
          
          start(vm_name, type)
        end
      end
    end
  end
end