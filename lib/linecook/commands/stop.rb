require 'linecook/commands/vbox_command'

module Linecook
  module Commands
    
    # ::desc stop a vm
    #
    # Stops one or more VirtualBox virtual machines using 'poweroff'.  By
    # default all virtual machines configured in config/ssh will be stopped.
    #
    class Stop < VboxCommand
      def process(*vm_names)
        each_vm_name(vm_names) do |vm_name|
          if running?(vm_name)
            stop(vm_name)
          end
        end
      end
    end
  end
end