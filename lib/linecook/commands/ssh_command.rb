require 'linecook/commands/command'

module Linecook
  module Commands
    class SshCommand < Command
      config :ssh_config_file, 'config/ssh'
      registry.delete_if {|key, value| value == self }
      
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
        hosts = {}

        File.open(ssh_config_file) do |io|
          io.each_line do |line|
            next unless line =~ HOST_REGEXP
            hosts[$1] = $2 || $1
          end
        end

        hosts
      end
      
      def each_host_name(host_names)
        if host_names.empty?
          host_names = hosts(ssh_config_file).keys
        end
        
        host_names.each do |host_name|
          yield(host_name)
        end
      end
      
      def each_vm_name(vm_names)
        if vm_names.empty?
          vm_names = hosts(ssh_config_file).values
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
      
      def scp_r(host, source, target)
        sh "scp -q -r -F '#{ssh_config_file}' '#{source}' '#{host}:#{target}'"
      end
      
      def scp_r!(host, source, target)
        unless scp_r(host, source, target)
          raise CommandError, "non-zero exit status: #{$?.exitstatus}"
        end
      end
    end
  end
end