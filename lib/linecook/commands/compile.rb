require 'fileutils'
require 'linecook/recipe'
require 'linecook/commands/compile_helper'
require 'yaml'
require 'csv'

module Linecook
  module Commands
    # ::desc compile recipes
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

      config :cookbook_path, [], :delimiter => ':'   # -C PATH : cookbook dirs
      config :helpers, []                            # -H NAME : use these helpers
      config :helper_dirs, []                        # -L DIRECTORY : compile helpers
      config :package_file, nil                      # -P PATH : package file
      config :input_dir, '.'                         # -i DIRECTORY : the base dir
      config :output_dir, '.'                        # -o DIRECTORY : the export dir
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

        package  = Linecook::Package.new(load_env(package_file))
        cookbook = Linecook::Cookbook.new(*cookbook_path)

        recipes.each do |recipe_name|
          if recipe_name == '-'
            recipe = Recipe.new(package, cookbook, $stdout)
            recipe.helper *helpers
            
            lineno = 0
            while line = gets
              recipe.instance_eval line, 'stdin', lineno
              lineno += 1
            end
          else
            recipe_path = cookbook.find(:recipes, recipe_name)

            target = package.add target_path(recipe_path)
            recipe = Recipe.new(package, cookbook, target)
            recipe.helper *helpers
            recipe._compile_ recipe_path
          end
        end

        package.export(output_dir)
      end

      def target_path(recipe_path)
        if recipe_path.index(input_dir) == 0
          base = recipe_path[input_dir.length + 1, recipe_path.length - input_dir.length]
          base.chomp(File.extname(recipe_path))
        else
          File.basename(recipe_path).chomp(File.extname(recipe_path))
        end
      end

      def load_env(package_file)
        package_file ? YAML.load_file(package_file) : {}
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