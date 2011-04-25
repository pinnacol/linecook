require 'linecook/commands/vbox_command'

module Linecook
  module Commands
    
    # :startdoc::desc print the vm state
    #
    # Prints the state of one or more VirtualBox virtual machines. By default
    # all virtual machines configured in config/ssh will print their state.
    #
    class State < VboxCommand
      config :hosts, false, :short => :n, &c.flag   # print state by host
      
      def state(vm_name)
        running?(vm_name) ? "running" : "stopped"
      end
      
      def process(*hosts)
        vm_names = resolve_vm_names(hosts)
        if hosts
          each_host(vm_names) do |host|
            puts "#{host}: #{state(host_map[host])}"
          end
        else
          each_vm_name(vm_names) do |vm_name|
            puts "#{vm_name}: #{state(vm_name)}"
          end
        end
      end
    end
  end
end