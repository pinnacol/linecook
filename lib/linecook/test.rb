require 'linecook/cookbook'
require 'linecook/package'
require 'linecook/test/file_test'
require 'linecook/test/shell_test'

module Linecook
  module Test
    include FileTest
    include ShellTest
    
    LINECOOK_DIR = File.expand_path('../../..', __FILE__)
    LINECOOK = File.join(LINECOOK_DIR, 'bin/linecook')
    
    def ssh_config_file
      method_ssh_config_file = path('config/ssh')
      File.file?(method_ssh_config_file) ? method_ssh_config_file : 'config/ssh'
    end
    
    # pick up user dir as a gem... bundler!
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
    
    def setup_helpers(*helpers)
      @helpers = helpers
    end
    
    def helpers
      @helpers ||= []
    end
    
    def setup_host(host)
      @host = host
    end
    
    def host
      @host or raise("no host set")
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
      
      cmd = ['2>&1', LINECOOK, cmd] + opts.sort + args
      cmd = cmd.join(' ')
      
      [sh(cmd), cmd]
    end
  end
end