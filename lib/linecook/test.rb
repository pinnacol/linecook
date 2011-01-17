require 'linecook/cookbook'
require 'linecook/package'
require 'linecook/test/file_test'
require 'linecook/test/shell_test'
require 'linecook/test/regexp_escape'
require 'linecook/utils'

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
    
    def script(options={}, &block)
      options = {
        :target_path => 'recipe',
        :export_dir  => path('packages')
      }.merge!(options)
      
      target_path = options[:target_path]
      export_dir  = options[:export_dir]
      
      recipe = setup_recipe(target_path)
      recipe.result(&block)
      
      package.export(export_dir)
      target_path
    end
    
    def script_test(cmd, options={}, &block)
      options = {
        :script_variable  => 'TEST_SCRIPT_PATH',
        :package_variable => 'TEST_PACKAGE_DIR',
        :export_dir       => path('packages')
      }.merge!(options)
      
      path = script(options, &block)
      export_dir = options[:export_dir]
      
      Dir.chdir(export_dir) do
        with_env(
          options[:script_variable]  => path,
          options[:package_variable] => export_dir
        ) do
          options = sh_test_options.merge(options)

          # strip indentiation if possible
          if cmd =~ /\A(?:\s*?\n)?( *)(.*?\n.*)\z/m
            indent, body = $1, $2

            if indent.length > 0 && options[:indents]
              cmd = body.gsub(/^ {0,#{indent.length}}/, '')
            end
          end

          cmd_pattern = options[:cmd_pattern]
          cmds, current = [], []

          cmd.each_line do |line|
            if line.index(cmd_pattern) == 0
              current = []
              cmds << [line, current]
            else
              current << line
            end
          end

          cmds.collect do |cmd, expected|
            result = sh(cmd, options)
            assert_equal(expected.join, result, cmd) unless expected.empty?
            result
          end
        end
      end
    end
  end
end