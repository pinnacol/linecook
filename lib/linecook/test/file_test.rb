module Linecook
  module Test
    module FileTest
      module ClassMethods
        attr_accessor :class_dir
        
        def self.extended(base)
          # Infers the test directory from the calling file.
          #   'some_class_test.rb' => 'some_class_test'
          calling_file = caller[2].gsub(/:\d+(:in .*)?$/, "")
          base.class_dir = calling_file.chomp(File.extname(calling_file))
        end
      end
    
      module ModuleMethods
        module_function
      
        def included(base)
          base.extend base.kind_of?(Class) ? ClassMethods : ModuleMethods
          super
        end
      end
    
      extend ModuleMethods
    
      attr_reader :user_dir
      attr_reader :method_dir
    
      def setup
        super
        @user_dir   = Dir.pwd
        @method_dir = File.expand_path(method_name, self.class.class_dir)
        cleanup method_dir
      end
    
      def teardown    
        unless ENV["KEEP_OUTPUTS"] == "true"
          cleanup class_dir
        end
      
        super
      end
    
      def cleanup(dir)
        FileUtils.rm_r(dir) if File.exists?(dir)
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
    
      def class_dir
        self.class.class_dir
      end
    end
  end
end
