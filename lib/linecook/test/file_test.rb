module Linecook
  module Test
    module FileTest
      module ClassMethods
        attr_accessor :class_dir
        
        attr_reader :cleanup_method_registry
        
        def cleanup_methods
          @cleanup_methods ||= begin
            cleanup_methods = {}

            ancestors.reverse.each do |ancestor|
              next unless ancestor.kind_of?(ClassMethods)
              ancestor.cleanup_method_registry.each_pair do |key, value|
                if value.nil?
                  cleanup_methods.delete(key)
                else
                  cleanup_methods[key] = value
                end
              end
            end
            
            cleanup_methods
          end
        end
        
        def reset_cleanup_methods
          @cleanup_methods = nil
        end
        
        protected
        
        def self.initialize(base)
          # Infers the test directory from the calling file.
          #   'some_class_test.rb' => 'some_class_test'
          calling_file = caller[1].gsub(/:\d+(:in .*)?$/, "")
          base.class_dir = calling_file.chomp(File.extname(calling_file))
          
          base.reset_cleanup_methods
          unless base.instance_variable_defined?(:@cleanup_method_registry)
            base.instance_variable_set(:@cleanup_method_registry, {})
          end
          
          unless base.instance_variable_defined?(:@cleanup_paths)
            base.instance_variable_set(:@cleanup_paths, ['.'])
          end
          
          unless base.instance_variable_defined?(:@cleanup)
            base.instance_variable_set(:@cleanup, true)
          end
        end
        
        def inherited(base) # :nodoc:
          ClassMethods.initialize(base)
          super
        end
        
        def define_method_cleanup(method_name, dirs)
          reset_cleanup_methods
          cleanup_method_registry[method_name.to_sym] = dirs
        end
        
        def remove_method_cleanup(method_name)
          reset_cleanup_methods
          cleanup_method_registry.delete(method_name.to_sym)
        end
        
        def undef_method_cleanup(method_name)
          reset_cleanup_methods
          cleanup_method_registry[method_name.to_sym] = nil
        end
        
        def cleanup_paths(*dirs)
          @cleanup_paths = dirs
        end
        
        def cleanup(*method_names)
          if method_names.empty?
            @cleanup = true
          else
            method_names.each do |method_name|
              define_method_cleanup method_name, @cleanup_paths
            end
          end
        end
        
        def no_cleanup(*method_names)
          if method_names.empty?
            @cleanup = false
          else
            method_names.each do |method_name|
              undef_method_cleanup method_name
            end
          end
        end
        
        def method_added(sym)
          if @cleanup && !cleanup_method_registry.has_key?(sym.to_sym) && sym.to_s[0, 5] == "test_"
            cleanup sym
          end
        end
      end
    
      module ModuleMethods
        module_function
      
        def included(base)
          base.extend ClassMethods
          base.extend ModuleMethods unless base.kind_of?(Class)
          
          ClassMethods.initialize(base)
          super
        end
      end
      
      extend ModuleMethods
      
      def setup
        super
        cleanup
      end
      
      def teardown
        Dir.chdir(user_dir)
        
        unless ENV["KEEP_OUTPUTS"] == "true"
          cleanup
          
          dir = method_dir
          while dir != class_dir
            dir = File.dirname(dir)
            Dir.rmdir(dir)
          end rescue(SystemCallError)
        end
        
        super
      end
      
      def user_dir
        @user_dir   ||= File.expand_path('.')
      end
      
      def class_dir
        @class_dir  ||= File.expand_path(self.class.class_dir, user_dir)
      end
      
      def method_dir
        @method_dir ||= File.expand_path(method_name.to_s, class_dir)
      end
      
      def cleanup_methods
        self.class.cleanup_methods
      end
      
      def cleanup
        if cleanup_paths = cleanup_methods[method_name.to_sym]
          cleanup_paths.each {|relative_path| remove(relative_path) }
        end
      end
      
      def path(relative_path)
        path = File.expand_path(relative_path, method_dir)
        
        unless path.index(method_dir) == 0
          raise "does not make a path relative to method_dir: #{relative_path.inspect}"
        end
        
        path
      end
      
      def prepare(relative_path, content=nil, &block)
        target = path(relative_path)
        
        if File.exists?(target)
          FileUtils.rm(target)
        else
          target_dir = File.dirname(target)
          FileUtils.mkdir_p(target_dir) unless File.exists?(target_dir)
        end
        
        FileUtils.touch(target)
        File.open(target, 'w') {|io| io << content } if content
        File.open(target, 'a', &block) if block
        
        target
      end
      
      def remove(relative_path)
        full_path = path(relative_path)
        FileUtils.rm_r(full_path) if File.exists?(full_path)
      end
    end
  end
end
