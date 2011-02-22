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
      def load_hosts(ssh_config_file)
        hosts = []
        
        File.open(ssh_config_file) do |io|
          io.each_line do |line|
            next unless line =~ HOST_REGEXP
            hosts << [$1, $2 || $1]
          end
        end
        
        hosts
      end
      
      def each_host(hosts)
        if hosts.empty?
          hosts = load_hosts(ssh_config_file).collect {|host, vm_name| host }
        end
        
        hosts.each do |host|
          yield(host)
        end
      end
      
      def each_vm_name(vm_names)
        if vm_names.empty?
          vm_names = load_hosts(ssh_config_file).collect {|host, vm_name| vm_name }
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
      
      def snapshots(vm_name)
        info = `VBoxManage -q showvminfo #{vm_name}`
        snapshots = {}
        
        stack = [{}]
        parent  = nil
        
        info.each_line do |line|
          next unless line =~ /^(\s+)Name\: (.*?) \(/
          depth = $1.length / 3
          name = $2
          
          if depth > stack.length
            stack.push stack.last[parent]
          elsif depth < stack.length
            stack.pop
          end
          
          snapshot = {}
          snapshots[name]  = snapshot
          stack.last[name] = snapshot
          parent = name
        end
        
        snapshots
      end
      
      def inside_out_each(key, value, &block)
        value.each_pair do |k, v|
          inside_out_each(k, v, &block)
        end
        
        yield(key)
      end
      
      def snapshot(vm_name, snapshot)
        snapshot = snapshot.upcase
        
        count = snapshots(vm_name).keys.grep(/\A#{snapshot}(?:_|\z)/).length
        if count > 0
          sh! "VBoxManage -q snapshot #{vm_name} edit #{snapshot} --name #{snapshot}_#{count - 1}"
        end
        
        sh! "VBoxManage -q snapshot #{vm_name} take #{snapshot}"
      end
      
      def restore_snapshot(vm_name, snapshot)
        stop(vm_name) if running?(vm_name)
        snapshot = snapshot.upcase
        
        hierarchy = snapshots(vm_name)
        parent = hierarchy.keys.select {|key| key =~ /\A#{snapshot}(?:_\d+)\z/ }.first
        parent ||= snapshot
        
        children = hierarchy[parent]
        children.each do |key, value|
          inside_out_each(key, value) do |child|
            sh! "VBoxManage -q snapshot #{vm_name} delete #{child}"
          end
        end
        
        sh! "VBoxManage -q snapshot #{vm_name} edit #{parent} --name #{snapshot}"
      end
      
      def share(vm_name, name, local_dir, remote_dir)
        share_dir = "#{local_dir}/#{vm_name}"
        FileUtils.mkdir_p(share_dir) unless File.exists?(share_dir)
        
        ssh vm_name, "sudo umount '#{remote_dir}' > /dev/null 2>&1"
        sh "VBoxManage sharedfolder remove '#{vm_name}' --name '#{name}' --transient > /dev/null 2>&1"
        sh! "VBoxManage sharedfolder add '#{vm_name}' --name '#{name}' --hostpath '#{share_dir}' --transient"
        ssh! vm_name, "sudo mount -t vboxsf -o uid=1000,gid=100 '#{name}' '#{remote_dir}'"
      end
      
      def start_ssh_socket(vm_name)
        sh "ssh -MNf -F '#{ssh_config_file}' '#{vm_name}' >/dev/null 2>&1 </dev/null"
      end
    end
  end
end