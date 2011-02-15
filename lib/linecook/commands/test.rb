require 'linecook/commands/command'
require 'linecook/commands/build'

module Linecook
  module Commands
    
    # ::desc 
    class Test < Command
      config :remote_test_dir, 'vm/test'
      # config :default_host, 'vbox'
      # config :keep_outputs, false
      config :shell, 'sh'
      config :force, false, &c.flag
      config :quiet, false, &c.flag # silence output
      
      SCRIPT = File.expand_path('../../../../bin/linecook_test', __FILE__)
      
      def process(project_dir='.')
        builder = Build.new(
          :project_dir => project_dir, 
          :force => force,
          :quiet => quiet
        )
        packages = builder.process
        
        ENV['REMOTE_TEST_DIR'] = remote_test_dir
        sh! "#{shell} #{SCRIPT} '#{project_dir}' '#{packages.join("' '")}'"
      end
    end
  end
end