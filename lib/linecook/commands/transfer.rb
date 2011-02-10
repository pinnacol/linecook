require 'linecook/commands/ssh_command'

module Linecook
  module Commands
    
    # ::desc transfer a directory to a vm
    class Transfer < SshCommand
      def process(host, source, target='package')
        unless File.directory?(source)
          raise "not a directory: #{source}"
        end
        
        target_dir = File.dirname(target)
        ssh host, "mkdir -p '#{target_dir}'"
        scp_r host, source, target
      end
    end
  end
end