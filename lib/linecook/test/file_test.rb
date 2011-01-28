require 'linecook/utils'

module Linecook
  module Test
    module FileTest
      TEST_DIR = ENV['TEST_DIR'] || 'test'
      
      attr_reader :user_dir
      attr_reader :test_dir
      attr_reader :class_dir
      attr_reader :method_dir
      
      def setup
        super
        
        @user_dir   = Dir.pwd
        @test_dir   = File.expand_path(TEST_DIR, user_dir)
        @class_dir  = File.expand_path(Linecook::Utils.underscore(self.class.to_s), test_dir)
        @method_dir = File.expand_path(method_name, class_dir)
        
        cleanup method_dir
      end
    
      def teardown    
        unless ENV["KEEP_OUTPUTS"] == "true"
          cleanup method_dir, class_dir
        end
      
        super
      end
      
      def cleanup(dir, base=dir)
        unless dir.index(base) == 0
          raise "invalid base directory"
        end
        
        if File.exists?(dir)
          FileUtils.rm_r(dir)
          
          while dir != base
            dir = File.dirname(dir)
          
            begin
              Dir.rmdir(dir)
            rescue(SystemCallError)
              break
            end
          end
        end
        
        dir
      end
      
      def path(relative_path)
        File.expand_path(relative_path, method_dir)
      end
      
      def prepare(relative_path, content=nil, &block)
        target = path(relative_path)
        
        target_dir = File.dirname(target)
        FileUtils.mkdir_p(target_dir) unless File.exists?(target_dir)
        
        FileUtils.touch(target)
        File.open(target, 'w') {|io| io << content } if content
        File.open(target, 'a', &block) if block
        
        target
      end
    end
  end
end
