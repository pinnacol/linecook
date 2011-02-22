require 'linecook/commands/vbox_command'

module Linecook
  module Commands
    
    # ::desc take a vm snapshop
    #
    # Takes the specified snapshot of one or more VirtualBox virtual machines.
    # By default all virtual machines configured in config/ssh will have a
    # snapshot taken.
    #
    class Snapshot < VboxCommand
      config :restore, false, &c.flag
      
      def process(snapshot, *vm_names)
        each_vm_name(vm_names) do |vm_name|
          if restore
            restore_snapshot(vm_name, snapshot)
          else
            snapshot(vm_name, snapshot)
          end
        end
      end
    end
  end
end