require 'linecook/vbox'

module Linecook
  module Commands
    VBOX = Vbox::DEFAULT_VM_NAME
    
    class VboxCommand < Command
      def control(vmname)
        yield Vbox.new(vmname)
        exit $?.exitstatus
      end
    end
    
    # Linecook::Commands::Start::desc start the vm
    class Start < VboxCommand
      config :type, 'headless'
      
      def process(vmname=VBOX)
        control(vmname) {|vbox| vbox.start(type) unless vbox.running? }
      end
    end
    
    # Linecook::Commands::Stop::desc stop the vm
    class Stop < VboxCommand
      def process(vmname=VBOX)
        control(vmname) {|vbox| vbox.stop if vbox.running? }
      end
    end
    
    # Linecook::Commands::Reset::desc reset vm to a snapshot
    class Reset < VboxCommand
      config :type, 'headless'
      
      def process(snapshot='base', vmname=VBOX)
        control(vmname) do |vbox|
          vbox.stop if vbox.running?
          
          vbox.reset(snapshot)
          exit $?.exitstatus unless $? == 0
          
          vbox.start(type)
        end
      end
    end
    
    # Linecook::Commands::Snapshot::desc take a snapshop
    class Snapshot < VboxCommand
      def process(snapshot, vmname=VBOX)
        control(vmname) {|vbox| vbox.snapshot(snapshot) }
      end
    end
    
    # Linecook::Commands::State::desc print the vm state
    class State < Command
      def process(vmname=VBOX)
        vbox = Vbox.new(vmname)
        puts(vbox.running? ? "running" : "stopped")
      end
    end
    
    # Linecook::Commands::Ssh::desc ssh to vm
    class Ssh < VboxCommand
      
      config :port, 2222, &c.integer
      config :user, 'vbox'
      config :vmname, VBOX
      config :keypath, File.expand_path('../../../../templates/vbox/ssh/id_rsa', __FILE__)
      
      def process(cmd=nil)
        control(vmname) {|vbox| vbox.ssh!(cmd, config) }
      end
    end
    
    # Linecook::Commands::Share::desc setup a vbox share
    class Share < VboxCommand
      def process(path='vbox', vmname=VBOX)
        control(vmname) {|vbox| vbox.share(path) }
      end
    end
  end
end