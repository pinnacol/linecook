module Linecook
  module Commands
    VBOX = ENV['vbox'] || 'vbox'
    
    # Linecook::Commands::Start::desc start the vm
    class Start < Command
      config :type, 'headless'
      
      def process(vmname=VBOX)
        unless `VBoxManage -q list runningvms`.include?(vmname)
          sh "VBoxManage -q startvm #{vmname} --type #{type}"
        end
      end
    end
    
    # Linecook::Commands::Stop::desc stop the vm
    class Stop < Command
      def process(vmname=VBOX)
        if `VBoxManage -q list runningvms`.include?(vmname)
          sh "VBoxManage -q controlvm #{vmname} poweroff"
        end
      end
    end
    
    # Linecook::Commands::Reset::desc reset vm to a snapshot
    class Reset < Command
      config :type, 'headless'
      
      def process(snapshot='base', vmname=VBOX)
        if `VBoxManage -q list runningvms`.include?(vmname)
          sh "VBoxManage -q controlvm #{vmname} poweroff"
        end

        sh "VBoxManage -q snapshot #{vmname} restore #{snapshot.upcase}"
        sh "VBoxManage -q startvm #{vmname} --type #{type}"
      end
    end
    
    # Linecook::Commands::Snapshot::desc take a snapshop
    class Snapshot < Command
      def process(snapshot, vmname=VBOX)
        `VBoxManage -q snapshot #{vmname} delete #{snapshot.upcase} > /dev/null`
        sh "VBoxManage -q snapshot #{vmname} take #{snapshot.upcase}"
      end
    end
    
    # Linecook::Commands::State::desc print the vm state
    class State < Command
      def process(vmname=VBOX)
        if `VBoxManage -q list runningvms`.include?(vmname)
          puts "running"
        else
          puts "stopped"
        end
      end
    end
    
    # Linecook::Commands::Ssh::desc ssh to vm
    class Ssh < Command
      
      config :port, 2222, &c.integer
      config :user, 'vbox'
      config :keypath, File.expand_path('vbox/ssh/id_rsa')
      
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
    
    # Linecook::Commands::Share::desc setup a vbox share
    class Share < Ssh
      def process(path='vbox', vmname=VBOX)
        path = File.expand_path(path)
        name = Time.now.strftime("vbox-#{File.basename(path)}-%Y%m%d%H%M%S")
        
        `VBoxManage sharedfolder add '#{vmname}' --name '#{name}' --hostpath '#{path}' --transient`
        super "sudo mount -t vboxsf -o uid=1000,gid=100 '#{name}' /vbox"
      end
    end
  end
end