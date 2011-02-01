module Linecook
  module Config
    module_function
    
    def hostnames(path)
      hostnames = []
      File.open(path) do |io|
        io.each_line do |line|
          next unless line =~ /^\s*Host\s+(\w+)/
          hostnames << $1 
        end
      end
      hostnames
    end
    
    DEFAULT_SSH_CONFIG_FILE = File.expand_path(ENV['LINECOOK_SSH_CONFIG_FILE'] || 'config/ssh')
    HOSTNAMES = Hash.new {|hash, path| hash[path] = hostnames(path) }
  end
end