require 'linecook/config'

module Linecook
  module Commands
    class VboxCommand < Command
      config :ssh_config_file, 'config/ssh'
      
      def hosts
        Config.hosts(ssh_config_file)
      end
      
      def each_vm_name(vm_names)
        if vm_names.empty?
          vm_names = hosts.values
        end
        
        vm_names.each do |vm_name|
          yield(vm_name)
        end
      end
      
      def sh(cmd)
        puts "% #{cmd}"
        system(cmd)
      end
      
      def sh!(cmd)
        unless sh(cmd)
          raise CommandError, "non-zero exit status: #{$?.exitstatus}"
        end
      end
      
      def ssh(host, cmd)
        sh "ssh -q -F '#{ssh_config_file}' '#{host}' -- #{cmd}"
      end
      
      def ssh!(host, cmd)
        unless ssh(host, cmd)
          raise CommandError, "non-zero exit status: #{$?.exitstatus}"
        end
      end
      
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
    
    # Linecook::Commands::Start::desc start a vm
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
    
    # Linecook::Commands::Stop::desc stop a vm
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
    
    # Linecook::Commands::Snapshot::desc take a snapshop
    #
    # Takes the specified snapshot of one or more VirtualBox virtual machines.
    # By default all virtual machines configured in config/ssh will have a
    # snapshot taken.
    #
    class Snapshot < VboxCommand
      def process(snapshot, *vm_names)
        each_vm_name(vm_names) do |vm_name|
          snapshot(vm_name, snapshot)
        end
      end
    end
    
    # Linecook::Commands::State::desc print the vm state
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
    
    # Linecook::Commands::Ssh::desc ssh to a vm
    #
    # Connects to a virtual machine using ssh, as configured in config/ssh.
    # 
    class Ssh < VboxCommand
      def process(host='vbox')
        ssh = "ssh -F '#{ssh_config_file}' '#{host}' --"
        puts ssh
        
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
    
    # Linecook::Commands::Share::desc setup a vm shared folder
    #
    # Sets up a shared folder with one or more VirtualBox virtual machines. By
    # default all virtual machines configured in config/ssh will share the
    # specified folder.  The virtual machines must be running for shares to be
    # established.
    # 
    class Share < VboxCommand
      def share(vm_name, path)
        name = Time.now.strftime("#{vm_name}-#{File.basename(path)}-%Y%m%d%H%M%S")
        
        sh! "VBoxManage sharedfolder add '#{vm_name}' --name '#{name}' --hostpath '#{path}' --transient"
        ssh! vm_name, "sudo mount -t vboxsf -o uid=1000,gid=100 '#{name}' /vbox"
      end
      
      def process(share_path='vbox', *vm_names)
        share_path = File.expand_path(share_path)
        
        each_vm_name(vm_names) do |vm_name|
          share(vm_name, share_path)
        end
      end
    end
  end
end