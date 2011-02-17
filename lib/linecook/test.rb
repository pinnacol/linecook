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
    
    def cookbook_dir
      File.directory?(method_dir) ? method_dir : user_dir
    end
    
    def setup_cookbook(config=cookbook_dir)
      @cookbook = Cookbook.setup(config)
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
    
    def set_helpers(*helpers)
      @helpers = helpers
    end
    
    def helpers
      @helpers ||= []
    end
    
    def set_host(host)
      @host = host
    end
    
    def host
      @host
    end
    
    def ssh_config_file
      method_ssh_config_file = path('config/ssh')
      File.file?(method_ssh_config_file) ? method_ssh_config_file : 'config/ssh'
    end
    
    def setup_recipe(target_name=package.next_target_name('recipe'), &block)
      recipe = package.setup_recipe(target_name)
      helpers.each {|helper| recipe.extend helper }
      
      recipe.instance_eval(&block) if block_given?
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
    
    def assert_recipe_output(expected, recipe=setup_recipe, &block)
      recipe.instance_eval(&block) if block_given?
      assert_package_output(expected, 'run_script' => recipe.target_name)
      recipe
    end
    
    def assert_recipe_output_matches(expected, recipe=setup_recipe, &block)
      recipe.instance_eval(&block) if block_given?
      assert_package_output_matches(expected, 'run_script' => recipe.target_name)
      recipe
    end
    
    def assert_package(expected)
      package.export path("packages/#{host}")
      assert_equal expected.keys.sort, package.registry.keys.sort
      
      expected.each_pair do |name, content|
        _assert_output_equal content, package.content(name)
      end
    end
    
    def assert_package_matches(expected)
      package.export path("packages/#{host}")
      assert_equal expected.keys.sort, package.registry.keys.sort
      
      expected.each_pair do |name, content|
        _assert_alike content, package.content(name)
      end
    end
    
    def assert_package_output(expected, options={})
      package.export path("packages/#{host}")
      result, exitstatus, cmd = linecook_run(options)
      
      assert_output_equal(expected, result, cmd)
    end
    
    def assert_package_output_matches(expected, options={})
      package.export path("packages/#{host}")
      result, exitstatus, cmd = linecook_run(options)
      assert_alike(expected, result, cmd)
      package
    end
    
    def assert_project_passes(options={})
      result, exitstatus, cmd = linecook_run(options)
      assert_equal 0, exitstatus, cmd
    end
    
    def assert_project_output(expected, options={})
      result, exitstatus, cmd = linecook_run(options)
      assert_output_equal expected, result, cmd
    end
    
    def assert_project_output_matches(expected, options={})
      result, exitstatus, cmd = linecook_run(options)
      assert_alike expected, result, cmd
    end
    
    def linecook(cmd, options={}, *args)
      opts = []
      options.each_pair do |key, value|
        key = key.to_s.gsub('_', '-')
        
        case value
        when true
          opts << "--#{key}"
        when false
        else 
          opts << "--#{key} '#{value}'"
        end
      end
      
      args = args.collect! {|arg| "'#{arg}'" }
      
      cmd = ['2>&1', LINECOOK, cmd] + opts.sort + args
      cmd = cmd.join(' ')
      
      [sh(cmd), $?.exitstatus, cmd]
    end
    
    def linecook_run(options={}, *packages)
      options = {
        :remote_dir  => "vm/#{method_dir[(user_dir.length + 1)..-1]}",
        :project_dir => method_dir,
        :quiet       => true
      }.merge(options)
      
      linecook 'run', options, *packages
    end
    
    def build_packages(*packages)
      cmd = "2>&1 #{LINECOOK} build --force --quiet --project-dir '#{method_dir}'"
      cmd += " '#{packages.join("' '")}'" unless packages.empty?
      
      result = sh(cmd)
      assert_equal(0, $?.exitstatus, "% #{cmd}")
      result
    end
    
    def assert_packages(*packages)
      relative_dir = method_dir[(user_dir.length + 1)..-1]
      
      cmd = "2>&1 #{LINECOOK} run --quiet --remote-dir 'vm/#{relative_dir}' --project-dir '#{method_dir}'"
      cmd += " '#{packages.join("' '")}'" unless packages.empty?
      
      result = sh(cmd)
      assert_equal(0, $?.exitstatus, "% #{cmd}")
      result
    end
  end
end