require 'linecook/vm'

module Linecook
  module Commands
    class VboxCommand < Command
      config :ssh_config_file, 'config/ssh'
      
      def hosts
        @hosts ||= Vm.hosts(ssh_config_file)
      end
      
      def each_vm_name(vm_names)
        if vm_names.empty?
          vm_names = hosts 
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
    
    # Linecook::Commands::Start::desc start the vm
    class Start < VboxCommand
      config :type, 'headless'
      
      def process(*vm_names)
        each_vm_name(vm_names) do |vm_name|
          unless running?(vm_name)
            start(vm_name)
          end
        end
      end
    end
    
    # Linecook::Commands::Stop::desc stop the vm
    class Stop < VboxCommand
      def process(*vm_names)
        each_vm_name(vm_names) do |vm_name|
          if running?(vm_name)
            stop(vm_name)
          end
        end
      end
    end
    
    # Linecook::Commands::Reset::desc reset vm to a snapshot
    class Reset < VboxCommand
      config :type, 'headless'
      
      def process(snapshot='base', *vm_names)
        each_vm_name(vm_names) do |vm_name|
          stop(vm_name) if running?(vm_name)
          reset(vm_name, snapshot)
          start(vm_name, type)
        end
      end
    end
    
    # Linecook::Commands::Snapshot::desc take a snapshop
    class Snapshot < VboxCommand
      def process(snapshot, *vm_names)
        each_vm_name(vm_names) do |vm_name|
          snapshot(vm_name, snapshot)
        end
      end
    end
    
    # Linecook::Commands::State::desc print the vm state
    class State < VboxCommand
      def process(*vm_names)
        each_vm_name(vm_names) do |vm_name|
          puts(running?(vm_name) ? "running" : "stopped")
        end
      end
    end
    
    # Linecook::Commands::Ssh::desc ssh to vm
    class Ssh < VboxCommand
      def process(host=hosts.first)
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
    
    # Linecook::Commands::Share::desc setup a vbox share
    class Share < VboxCommand
      def share(vm_name, path)
        name = Time.now.strftime("#{vm_name}-#{File.basename(path)}-%Y%m%d%H%M%S")
        
        sh! "VBoxManage sharedfolder add '#{vm_name}' --name '#{name}' --hostpath '#{path}' --transient"
        ssh! vm_name, "sudo mount -t vboxsf -o uid=1000,gid=100 '#{name}' /vbox"
      end
      
      def process(path='vbox', *vm_names)
        path = File.expand_path(path)
        
        each_vm_name(vm_names) do |vm_name|
          share(vm_name, path)
        end
      end
    end
  end
end