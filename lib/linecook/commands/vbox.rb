require 'linecook/vbox'

module Linecook
  module Commands
    VBOX = Linecook::DEFAULT_VM_NAME
    HOSTNAME = Linecook::DEFAULT_HOSTNAME
    
    # Linecook::Commands::Start::desc start the vm
    class Start < Command
      config :type, 'headless'
      
      def process(vm_name=VBOX)
        vbox = Vbox.new(vm_name)
        
        unless vbox.running?
          system vbox.start(type)
        end
      end
    end
    
    # Linecook::Commands::Stop::desc stop the vm
    class Stop < Command
      def process(vm_name=VBOX)
        vbox = Vbox.new(vm_name)

        if vbox.running?
          system vbox.stop
        end
      end
    end
    
    # Linecook::Commands::Reset::desc reset vm to a snapshot
    class Reset < Command
      config :type, 'headless'
      
      def process(snapshot='base', vm_name=VBOX)
        vbox = Vbox.new(vm_name)

        system vbox.stop if vbox.running?
        system vbox.reset(snapshot)
        system vbox.start(type)
      end
    end
    
    # Linecook::Commands::Snapshot::desc take a snapshop
    class Snapshot < Command
      def process(snapshot, vm_name=VBOX)
        vbox = Vbox.new(vm_name)
        system vbox.snapshot(snapshot)
      end
    end
    
    # Linecook::Commands::State::desc print the vm state
    class State < Command
      def process(vm_name=VBOX)
        vbox = Vbox.new(vm_name)
        puts(vbox.running? ? "running" : "stopped")
      end
    end
    
    # Linecook::Commands::Ssh::desc ssh to vm
    class Ssh < Command
      config :vm_name, VBOX
      config :hostname, HOSTNAME
      config :ssh_config_file, 'config/ssh'
      
      def process(cmd=nil)
        vbox = Vbox.new(vm_name)
        ssh = vbox.ssh(cmd, config)
      
        # Patterned after vagrant/ssh.rb (circa 0.6.6)
        # Some hackery going on here. On Mac OS X Leopard (10.5), exec fails
        # (GH-51). As a workaround, we fork and wait. On all other platforms, we
        # simply exec.
    
        platform = RUBY_PLATFORM.to_s.downcase
        pid = nil
        pid = fork if platform.include?("darwin9") || platform.include?("darwin8")
        Kernel.exec(ssh)  if pid.nil?
        Process.wait(pid) if pid
        
        exit $?.exitstatus
      end
    end
    
    # Linecook::Commands::Share::desc setup a vbox share
    class Share < Command
      config :vm_name, VBOX
      config :hostname, HOSTNAME
      config :config_file, 'config/ssh'
      
      def process(path='vbox')
        vbox = Vbox.new(vm_name)
        system vbox.share(path, config)
      end
    end
  end
end