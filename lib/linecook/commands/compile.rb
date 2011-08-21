require 'fileutils'
require 'linecook/recipe'
require 'linecook/commands/compile_helper'
require 'yaml'
require 'csv'

module Linecook
  module Commands
    # ::desc compile recipes
    #
    # Compiles a list of recipes into a single package and exports the result
    # to the working directory (pwd).  The recipes are added to the package at
    # their path relative to pwd minus their extname, making this type of use
    # possible:
    #
    #   $ echo "write 'echo hello world'" > recipe.rb 
    #   $ linecook compile recipe.rb
    #   $ sh recipe
    #   hello world
    #
    # The base dir for determining package paths and the export dir can both
    # be set with options.  Providing '-' as a recipe will cause stdin to be
    # treated as a recipe and the output printed to stdout; any files added to
    # the package will be also be exported to pwd.
    #
    class Compile < Command
      class << self
        def parse(argv=ARGV)
          super(argv) do |options|
            options.on('-I DIRECTORY', 'prepend to LOAD_PATH') do |path|
              $LOAD_PATH.unshift File.expand_path(path)
            end

            options.on('-r LIBRARY', 'require the library') do |path|
              require(path)
            end

            if block_given?
              yield(options)
            end
          end
        end
      end

      pwd = Dir.pwd
      config :cookbook_path, [], :delimiter => ':'   # -C PATH : cookbook dirs
      config :helpers, []                            # -H NAME : use these helpers
      config :helper_dirs, []                        # -L DIRECTORY : compile helpers
      config :package_file, nil                      # -P PATH : package file
      config :input_dir, pwd                         # -i DIRECTORY : the base dir
      config :output_dir, pwd                        # -o DIRECTORY : the export dir
      config :force, false                           # -f : overwrite existing

      def input_dir=(input)
        @input_dir = File.expand_path(input)
      end

      def output_dir=(input)
        @output_dir = File.expand_path(input)
      end

      def process(*recipes)
        helper_dirs.each do |helper_dir|
          compile_helpers(helper_dir)
        end

        package  = Package.new(load_env(package_file))
        cookbook = Cookbook.new(*cookbook_path)

        recipes.each do |recipe_name|
          if recipe_name == '-'
            recipe = Recipe.new(package, cookbook, $stdout)
            recipe.helper *helpers
            recipe.instance_eval $stdin.read, 'stdin'
          else
            recipe_path = cookbook.find(:recipes, recipe_name)
            target_path = basepath(recipe_path, input_dir)
            target = package.add target_path

            recipe = Recipe.new(package, cookbook, target)
            recipe.helper *helpers
            recipe._compile_ recipe_path
          end
        end

        package.export(output_dir) do |src, dest|
          unless force
            raise CommandError, "already exists: #{dest.inspect}"
          end

          FileUtils.rm_rf(dest)
          true
        end
      end

      def basepath(path, dir=nil)
        extname = File.extname(path)
        if dir && path.index(dir) == 0 && path != dir
          path[dir.length + 1, path.length - dir.length].chomp(extname)
        else
          File.basename(path).chomp(extname)
        end
      end

      def load_env(package_file)
        env = package_file && File.exists?(package_file) ? YAML.load_file(package_file) : nil
        env.nil? ? {} : env
      end

      def glob_helpers(helper_dir)
        sources = {}
        helpers = []

        Dir.glob("#{helper_dir}/*/**/*").each do |source_file|
          next if File.directory?(source_file)
          (sources[File.dirname(source_file)] ||= []) << source_file
        end

        sources.each_pair do |dir, source_files|
          name = dir[(helper_dir.length + 1)..-1]
          helpers << [name, source_files]
        end

        helpers.sort_by {|name, source_files| name }
      end

      def compile_helpers(helper_dir)
        compiler = CompileHelper.new(
          :force => force,
          :quiet => true
        )

        helpers = glob_helpers(helper_dir)
        helpers.each do |(name, sources)|
          compiler.process(name, *sources)
        end

        $LOAD_PATH.unshift compiler.output_dir
      end
    end
  end
end