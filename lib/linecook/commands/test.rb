require 'linecook/commands/ssh_command'

module Linecook
  module Commands
    
    # ::desc 
    class Test < SshCommand
      config :remote_test_dir, 'vm/test'
      # config :default_host, 'vbox'
      # config :keep_outputs, false
      config :shell, 'sh'
      
      SCRIPT = File.expand_path('../../../../bin/linecook_test', __FILE__)
      
      def process(project_dir='.')
        ENV['REMOTE_TEST_DIR'] = remote_test_dir
        sh! "time #{shell} #{SCRIPT} #{project_dir}"
      end
    end
  end
end