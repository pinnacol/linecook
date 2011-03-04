require 'linecook/package'
require 'linecook/test/file_test'
require 'linecook/test/shell_test'

module Linecook
  module Test
    module ClassMethods
      def host
        @host ||= ENV['LINECOOK_TEST_HOST'] || 'test'
      end
      
      def use_host(host)
        @host = host
      end
      
      def only_hosts(*patterns)
        patterns.collect! do |pattern|
          pattern.kind_of?(Regexp) ? pattern : /\A#{pattern}\z/
        end
        
        @skip_test_suite = false
        unless patterns.any? {|pattern| host =~ pattern }
          skip_test "not for host (#{host})"
        end
      end
      
      # Causes a test suite to be skipped.  If a message is given, it will
      # print and notify the user the test suite has been skipped.
      def skip_test(msg=nil)
        @skip_test_suite = true
        skip_messages << msg
      end
      
      # Modifies the default suite method to skip the suit unless
      # run_test_suite is true.  If the test is skipped, the skip_messages 
      # will be printed along with the default 'Skipping <Test>' message.
      def suite # :nodoc:
        if (@skip_test_suite ||= false)
          skip_message = skip_messages.compact.join(', ')
          puts "Skipping #{name}#{skip_message.empty? ? '' : ': ' + skip_message}"

          # return an empty test suite of the appropriate name
          ::Test::Unit::TestSuite.new(name)
        else
          super
        end
      end
      
      protected
      
      def skip_messages # :nodoc:
        @skip_messages ||= []
      end
    end
  
    module ModuleMethods
      module_function
    
      def included(base)
        base.extend ClassMethods
        base.extend ModuleMethods unless base.kind_of?(Class)
        super
      end
    end
    
    extend ModuleMethods
    
    include FileTest
    include ShellTest
    
    LINECOOK_DIR = File.expand_path('../../..', __FILE__)
    LINECOOK = File.join(LINECOOK_DIR, 'bin/linecook')
    
    def ssh_config_file
      method_ssh_config_file = path('config/ssh')
      File.file?(method_ssh_config_file) ? method_ssh_config_file : 'config/ssh'
    end
    
    def setup_cookbook(configs=nil, project_dir=method_dir)
      configs ||= Cookbook.config_file(project_dir)
      @cookbook = Cookbook.setup(configs, project_dir)
    end
    
    def cookbook
      @cookbook ||= setup_cookbook
    end
    
    def setup_package(env={})
      @package = Package.setup(env, cookbook)
    end
    
    def package
      @package ||= setup_package
    end
    
    def use_helpers(*helpers)
      @helpers = helpers
    end
    
    def helpers
      @helpers ||= []
    end
    
    def use_host(host)
      @host = host
    end
    
    def host
      @host ||= self.class.host
    end
    
    def runlist
      @runlist ||= []
    end
    
    def setup_recipe(target_name=package.next_target_name('recipe'), &block)
      recipe = package.setup_recipe(target_name)
      helpers.each {|helper| recipe.extend helper }
      
      recipe.instance_eval(&block) if block_given?
      runlist << target_name
      
      @recipe = recipe
    end
    
    def recipe
      @recipe ||= setup_recipe
    end
    
    def assert_recipe(expected, recipe=setup_recipe, &block)
      recipe.instance_eval(&block) if block_given?
      assert_output_equal expected, recipe.result
      recipe
    end
    
    def assert_recipe_matches(expected, recipe=setup_recipe, &block)
      recipe.instance_eval(&block) if block_given?
      assert_alike expected, recipe.result
      recipe
    end
    
    def build_package(host=self.host)
      package_dir = path("packages/#{host}")
      
      package.build
      package.export package_dir
      
      package_dir
    end
    
    def run_package(options={}, host=self.host)
      options['runlist'] ||= prepare('runlist') {|io| io.puts runlist.join("\n") }
      
      build_package host
      run_project options, host
    end
    
    def build_project(options={})
      options = {
        'project_dir' => method_dir,
        'quiet'       => true
      }.merge(options)
      
      linecook('build', options)
    end
    
    # pick up user dir as a gem... bundler!
    def run_project(options={}, *package_names)
      options = {
        'ssh_config_file' => ssh_config_file,
        'project_dir'     => method_dir,
        'remote_dir'      => method_dir[(user_dir.length + 1)..-1],
        'quiet'           => true,
      }.merge(options)
      
      linecook('run', options, *package_names)
    end
    
    def linecook(cmd, options={}, *args)
      stdout = prepare("log/#{cmd}.out")
      stderr = prepare("log/#{cmd}.err")
      
      command = "#{linecook_cmd(cmd, options, *args)} 2> '#{stderr}' > '#{stdout}'"
      system(command)
      
      [File.read(stdout), "% #{command}\n#{File.read(stderr)}"]
    end
    
    def linecook_cmd(cmd, options={}, *args)
      opts = []
      options.each_pair do |key, value|
        key = key.gsub('_', '-')
        
        case value
        when true
          opts << "--#{key}"
        when nil, false
        else 
          opts << "--#{key} '#{value}'"
        end
      end
      
      args = args.collect! {|arg| "'#{arg}'" }
      
      cmd = [LINECOOK, cmd] + opts.sort + args
      cmd.join(' ')
    end
  end
end