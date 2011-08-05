require 'linecook/commands/virtual_box_command'

module Linecook
  module Commands

    # :startdoc::desc ssh to a vm
    #
    # Connects to a virtual machine using ssh, as configured in config/ssh.
    #
    class Ssh < VirtualBoxCommand
      undef_config :names

      def default_host
        load_hosts(ssh_config_file).collect {|host, vm_name| host }.first
      end

      def process(host=default_host)
        if host.to_s.strip.empty?
          raise CommandError.new("no host specified")
        end

        ssh = "ssh -F '#{ssh_config_file}' '#{host}' --"

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
  end
end