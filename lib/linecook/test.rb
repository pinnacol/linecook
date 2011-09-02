require 'shell_test'
require 'linecook/recipe'
require 'pty'

module Linecook
  module Test
    module ClassMethods

      # Nil host ends up falling through to the default as configured
      # in config/ssh
      def host
        @host ||= ENV['LINECOOK_TEST_HOST'] || name
      end

      def use_host(host)
        @host = host
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
    include ShellTest

    LINECOOK_DIR = File.expand_path('../../..', __FILE__)
    LINECOOK = File.join(LINECOOK_DIR, 'bin/linecook')

    def method_dir
      @host_method_dir ||= begin
        if test_host = ENV['LINECOOK_TEST_HOST']
          File.join(super, test_host)
        else
          super
        end
      end
    end

    def remote_dir
      method_dir[(user_dir.length + 1)..-1]
    end

    def ssh_config_file
      method_ssh_config_file = path('config/ssh')
      File.file?(method_ssh_config_file) ? method_ssh_config_file : 'config/ssh'
    end

    def setup_cookbook(project_dir=method_dir, *additional_project_dirs)
      @cookbook = Cookbook.new(project_dir, *additional_project_dirs)
    end

    def cookbook
      @cookbook ||= setup_cookbook
    end

    def setup_package(env={})
      @package = Package.new(env)
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

    def setup_recipe(target_path=package.next_target_path('recipe'), &block)
      target = package.add(target_path, :mode => 0744)
      recipe = Recipe.new(package, cookbook, target)
      helpers.each {|helper| recipe.extend helper }

      recipe.instance_eval(&block) if block_given?
      runlist << target_path

      @recipe = recipe
    end

    def recipe
      @recipe ||= setup_recipe
    end

    def assert_recipe(expected, recipe=setup_recipe, &block)
      recipe.instance_eval(&block) if block_given?
      assert_str_equal expected, recipe._result_
      recipe
    end

    def assert_recipe_matches(expected, recipe=setup_recipe, &block)
      recipe.instance_eval(&block) if block_given?
      assert_str_match expected, recipe._result_
      recipe
    end

    def export_package(host=self.host)
      package_dir = path("packages/#{host}")
      package.export package_dir
      package_dir
    end

    def run_package(options={}, host=self.host, &block)
      options['S'] ||= runlist.join(',')
      run_project options, export_package(host), &block
    end

    def build_project(options={})
      options = {
        'L' => 'helpers',
        'C' => method_dir,
        'i' => path('packages'),
        'o' => path('packages')
      }.merge(options)

      Dir.chdir method_dir do
        linecook('build', options, *glob('recipes/*.rb'))
      end
    end

    def run_project(options={}, *package_dirs, &block)
      if package_dirs.empty?
        package_dirs = glob('packages/*').select {|path| File.directory?(path) }
      end

      options = {
        'F' => ssh_config_file,
        'D' => remote_dir,
        'q' => true
      }.merge(options)

      linecook('run', options, *package_dirs, &block)
    end

    def linecook(cmd, options={}, *args, &block)
      command = linecook_cmd(cmd, options, *args)
      output, status = pty(command, &block)

      [output.to_s.gsub(/\r\n/, "\n"), "$ #{command}"]
    end

    def pty(command)
      buffer  = ''
      timeout = 5
      PTY.spawn(command) do |r,w,pid|
        while true
          if !IO.select([r],nil,nil,timeout)
            Process.kill(9, pid)
            break
          end

          if r.eof?
            break
          end

          # Use readpartial instead of read because it will not block if the
          # length is not fully available.
          #
          # Use readpartial+select instead of read_nonblock to avoid polling
          # in a tight loop.
          buffer << r.readpartial(1024)
        end
        Process.wait(pid)
      end
      buffer
    end

    def linecook_cmd(cmd, options={}, *args)
      opts = []
      options.each_pair do |key, value|
        key = key.to_s.gsub('_', '-')
        key = key.length == 1 ? "-#{key}" : "--#{key}"

        case value
        when true
          opts << key
        when nil, false
        else
          opts << "#{key} '#{value}'"
        end
      end

      args = args.collect! {|arg| "'#{arg}'" }

      cmd = [LINECOOK, cmd] + opts.sort + args
      cmd.join(' ')
    end
  end
end