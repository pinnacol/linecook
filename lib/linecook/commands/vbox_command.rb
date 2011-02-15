require 'linecook/commands/command'

module Linecook
  module Commands
    class VboxCommand < Command
      registry.delete_if {|key, value| value == self }
      
      config :ssh_config_file, 'config/ssh'
      
      # Matches a host declaration in a ssh config file. After the match:
      #
      #   $1:: The host name
      #        (ex: 'Host name' => 'name')
      #   $2:: The vm name (if present)
      #        (ex: 'Host name # [vm_name]' => 'vm_name')
      #
      HOST_REGEXP = /^\s*Host\s+(\w+)(?:\s*#\s*\[(\w+)\])?/
      
      # Returns a hash of (host, vm_name) pairs as declared in a ssh config
      # file.  Basically this means parsing out the name in each config like:
      #
      #   Host name
      #
      # Normally the vm_name is the same as the host name, but an alternate can
      # be specified as a comment in the form:
      #
      #   Host name # [vm_name]
      #
      def hosts(ssh_config_file)
        hosts = []
        
        File.open(ssh_config_file) do |io|
          io.each_line do |line|
            next unless line =~ HOST_REGEXP
            hosts << [$1, $2 || $1]
          end
        end
        
        hosts
      end
      
      def each_vm_name(vm_names)
        if vm_names.empty?
          vm_names = hosts(ssh_config_file).collect {|host, vm_name| vm_name }
        end
        
        vm_names.each do |vm_name|
          yield(vm_name)
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
      
      def share(vm_name, name, local_dir, remote_dir)
        ssh vm_name, "sudo umount '#{remote_dir}' > /dev/null 2>&1"
        sh "VBoxManage sharedfolder remove '#{vm_name}' --name '#{name}' --transient > /dev/null 2>&1"
        sh! "VBoxManage sharedfolder add '#{vm_name}' --name '#{name}' --hostpath '#{local_dir}' --transient"
        ssh! vm_name, "sudo mount -t vboxsf -o uid=1000,gid=100 '#{name}' '#{remote_dir}'"
      end
    end
  end
end