require 'linecook/commands/ssh_command'

module Linecook
  module Commands
    
    # ::desc 
    class Test < SshCommand
      config :remote_test_dir, 'vm/test'
      # config :default_host, 'vbox'
      # config :keep_outputs, false
      config :script, 'test/test_package.sh'
      config :shell, 'sh'
      
      def process(project_dir='.')
        ENV['REMOTE_TEST_DIR'] = remote_test_dir
        sh! "time #{shell} #{script} #{project_dir}"
      end
    end
  end
end