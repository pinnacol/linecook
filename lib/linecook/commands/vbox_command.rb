require 'linecook/commands/ssh_command'

module Linecook
  module Commands
    class VboxCommand < SshCommand
      registry.delete_if {|key, value| value == self }
      
      def running?(vm_name)
        `VBoxManage -q list runningvms`.include?(vm_name)
      end
      
      def start(vm_name, type='headless')
        sh! "VBoxManage -q startvm #{vm_name} --type #{type}"
      end
      
      def stop(vm_name)
        sh! "VBoxManage -q controlvm #{vm_name} poweroff"
      end
      
      def reset(vm_name, snapshot)
        sh! "VBoxManage -q snapshot #{vm_name} restore #{snapshot.upcase}"
      end
      
      def snapshot(vm_name, snapshot)
        sh "VBoxManage -q snapshot #{vm_name} delete #{snapshot.upcase} > /dev/null"
        sh! "VBoxManage -q snapshot #{vm_name} take #{snapshot.upcase}"
      end
    end
  end
end