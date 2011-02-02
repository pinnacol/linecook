module Linecook
  module Vm
    module_function
    
    def hosts(path)
      hosts = []
      
      if File.exists?(path)
        File.open(path) do |io|
          io.each_line do |line|
            next unless line =~ /^\s*Host\s+(\w+)/
            hosts << $1 
          end
        end
      end
      
      hosts
    end
    
    DEFAULT_SSH_CONFIG_FILE = File.expand_path(ENV['LINECOOK_SSH_CONFIG_FILE'] || 'config/ssh')
    DEFAULT_HOSTS = hosts(DEFAULT_SSH_CONFIG_FILE)
    DEFAULT_HOST  = ENV['LINECOOK_DEFAULT_HOST'] || DEFAULT_HOSTS.first || 'vbox'
  end
end