module Linecook
  module Commands
    
    # ::desc vm_name
    # start the vm
    class Start < Command
      config :type, 'headless'
      
      def process(vmname='vbox')
        unless `VBoxManage -q list runningvms`.include?(VMNAME)
          sh "VBoxManage -q startvm #{vmname} --type #{type}"
        end
      end
    end
    
    # ::desc vm_name
    # stop the vm
    class Stop < Command
      def process(vmname='vbox')
        if `VBoxManage -q list runningvms`.include?(vmname)
          sh "VBoxManage -q controlvm #{vmname} poweroff"
        end
      end
    end
    
    # ::desc vm_name
    # reset the vm to a snapshot
    class Reset < Command
      
      config :type, 'headless'
      config :snapshot, 'BASE'
      
      def process(vmname='vbox')
        if `VBoxManage -q list runningvms`.include?(vmname)
          sh "VBoxManage -q controlvm #{vmname} poweroff"
        end

        sh "VBoxManage -q snapshot #{vmname} restore #{snapshot.upcase}"
        sh "VBoxManage -q startvm #{vmname} --type #{type}"
      end
    end
    
    # ::desc snapshot, vm_name
    # take a snapshop
    class Snapshot < Command
      def process(snapshot, vmname='vbox')
        `VBoxManage -q snapshot #{vmname} delete #{snapshot.upcase} > /dev/null`
        sh "VBoxManage -q snapshot #{vmname} take #{snapshot.upcase}"
      end
    end
    
    # ::desc vm_name
    class State < Command
      def process(vmname='vbox')
        if `VBoxManage -q list runningvms`.include?(vmname)
          puts "running"
        else
          puts "stopped"
        end
      end
    end
    
    # ::desc cmd
    # ssh to a vm and execute a command
    class Ssh < Command
      
      config :port, 2222, &c.integer
      config :user, 'vbox'
      config :keypath, File.expand_path('../../../../vbox/ssh/id_rsa', __FILE__)
      
      def process(cmd=nil)
        # To prevent ssh errors, protect the private key
        FileUtils.chmod(0600, keypath)

        # Patterned after vagrant/ssh.rb (circa 0.6.6)
        platform = RUBY_PLATFORM.to_s.downcase
        ssh = "ssh -p #{port} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i #{keypath} #{user}@localhost #{cmd}"

        # Some hackery going on here. On Mac OS X Leopard (10.5), exec fails
        # (GH-51). As a workaround, we fork and wait. On all other platforms, we
        # simply exec.

        pid = nil
        pid = fork if platform.include?("darwin9") || platform.include?("darwin8")
        Kernel.exec(ssh)  if pid.nil?
        Process.wait(pid) if pid
      end
    end
  end
end