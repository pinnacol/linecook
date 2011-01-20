require 'linecook/cookbook'
require 'linecook/package'
require 'linecook/test/file_test'
require 'linecook/test/shell_test'
require 'linecook/test/regexp_escape'
require 'linecook/utils'
require 'linecook/vbox'

module Linecook
  module Test
    include FileTest
    include ShellTest
    
    attr_writer :cookbook
    attr_writer :package
    
    def cookbook_dir
      user_dir
    end
    
    def cookbook
      @cookbook ||= Cookbook.init(cookbook_dir)
    end
    
    def setup_package(env={})
      @package = Package.init(env, cookbook)
    end
    
    def package
      @package ||= setup_package
    end
    
    def setup_recipe(target_path='recipe')
      @recipe = package.reset.recipe(target_path)
    end
    
    def recipe
      @recipe ||= setup_recipe
    end
    
    def assert_recipe(expected, &block)
      recipe = setup_recipe
      assert_output_equal expected, recipe.result(&block)
      recipe
    end
    
    def assert_recipe_match(expected, &block)
      recipe = setup_recipe
      assert_alike expected, recipe.result(&block)
      recipe
    end
    
    def build(options={}, &block)
      options = {
        :env         => {},
        :target_path => 'recipe',
        :export_dir  => path('packages')
      }.merge(options)
      
      setup_package options[:env]
      
      if block_given?
        recipe = setup_recipe options[:target_path]
        recipe.result(&block)
      end
      
      package.export options[:export_dir]
      package
    end
    
    def script_test(cmd, options={}, &block)
      options = {
        :export_dir => path('packages')
      }.merge(options)
      
      build(options, &block)
      
      Dir.chdir(options[:export_dir]) do
        sh_test(cmd, options)
      end
    end
    
    def ssh_config_file
      @ssh_config_file ||= begin
        default = File.expand_path('config/ssh', user_dir)
        File.file?(default) ? default : nil
      end
    end

    def ssh(cmd, options={})
      options = {
        :opts => ssh_config_file ? "-q -F #{ssh_config_file}" : nil,
        :host => 'vbox'
      }.merge(options)

      cmd = ['ssh', options[:opts], options[:host], cmd].compact.join(' ')

      sh(cmd, options)
    end
    
    def scp(source, target, options={})
      options = {
        :opts => ssh_config_file ? "-q -r -F #{ssh_config_file}" : nil,
        :host => 'vbox'
      }.merge(options)

      cmd = ['scp', options[:opts], source, "#{options[:host]}:#{target}"].compact.join(' ')

      sh(cmd, options)
    end
    
    def ssh_test(cmd, options={})
      options = sh_test_options.merge(options)

      # strip indentiation if possible
      if cmd =~ /\A(?:\s*?\n)?( *)(.*?\n)(.*)\z/m
        indent, cmd, expected = $1, $2, $3
        cmd.strip!

        if indent.length > 0 && options[:indents]
          expected.gsub!(/^ {0,#{indent.length}}/, '')
        end
      end

      result = ssh(cmd, options)

      assert_equal(expected, result, cmd) if expected
      yield(result) if block_given?
      result
    end
    
    def vbox_test(cmd, options={}, &block)
      build(options, &block)
      scp path('packages'), method_name
      
      ssh_test(cmd, options)
    end
  end
end