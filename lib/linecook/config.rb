module Linecook
  module Config
    module_function
    
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
    
    # The default ssh config file
    DEFAULT_SSH_CONFIG_FILE = ENV['LINECOOK_SSH_CONFIG_FILE'] || 'config/ssh'
    
    # The default host
    DEFAULT_HOST = ENV['LINECOOK_DEFAULT_HOST'] || 'vbox'
  end
end