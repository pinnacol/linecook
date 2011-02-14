require 'linecook/commands/vbox_command'

module Linecook
  module Commands
    
    # ::desc print the vm state
    #
    # Prints the state of one or more VirtualBox virtual machines. By default
    # all virtual machines configured in config/ssh will print their state.
    #
    class State < VboxCommand
      def state(vm_name)
        running?(vm_name) ? "running" : "stopped"
      end
      
      def process(*vm_names)
        each_vm_name(vm_names) do |vm_name|
          puts "#{vm_name}: #{state(vm_name)}"
        end
      end
    end
  end
end