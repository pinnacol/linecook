require 'linecook/command'
require 'linecook/command_utils'

module Linecook
  module Commands
    class VirtualBoxCommand < Command
      include CommandUtils

      config :ssh_config_file, 'config/ssh', {   # -F FILE : the ssh config file
        :writer => :ssh_config_file= 
      }
      config :names, false                       # -n, --names : use vm names

      # Matches a host declaration in a ssh config file. After the match:
      #
      #   $1:: The host name
      #        (ex: 'Host name' => 'name')
      #   $2:: The vm name (if present)
      #        (ex: 'Host name # [vm_name]' => 'vm_name')
      #
      HOST_REGEXP = /^\s*Host\s+([^\s#]+)(?:\s*#\s*\[(.*?)\])?/

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
            next if $2 && $2.strip.empty?
            hosts << [$1, $2 || $1]
          end
        end

        hosts
      end

      def ssh_config_file=(ssh_config_file)
        @ssh_config_file = ssh_config_file
        @host_list = nil
        @host_map  = nil
      end

      def host_list
        @host_list ||= load_hosts(ssh_config_file)
      end

      def host_map
        @host_map ||= Hash[*host_list.flatten]
      end

      def resolve_vm_names(hosts)
        names ? hosts : hosts.collect {|host| host_map[host] || host }
      end

      def each_host(hosts=[])
        if hosts.empty?
          hosts = host_list.collect {|host, vm_name| host }
          hosts.delete('*')
        end

        hosts.uniq.each do |host|
          yield(host)
        end
      end

      def each_vm_name(vm_names=[])
        if vm_names.empty?
          vm_names = host_list.collect {|host, vm_name| vm_name }
          vm_names.delete('*')
        end

        vm_names.uniq.each do |vm_name|
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

      def restore(vm_name, snapshot)
        sh! "VBoxManage -q snapshot #{vm_name} restore #{snapshot.upcase}"
      end

      def discardstate(vm_name)
        sh! "VBoxManage discardstate #{vm_name}"
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