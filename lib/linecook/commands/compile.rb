require 'fileutils'
require 'linecook/recipe'
require 'linecook/commands/compile_helper'

module Linecook
  module Commands
    # ::desc compile recipes, helpers, packages
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

      config :helpers, []          # -H DIRECTORY : compile helpers
      config :output_dir, '.'      # -o DIRECTORY : specify the output dir
      config :script_name, 'run'   # -s NAME : specify the script name
      config :executable, false    # -x : make the script executable
      config :force, false         # -f : overwrite existing

      def output_dir=(input)
        @output_dir = File.expand_path(input)
      end

      def process(*recipes)
        helpers.each do |helpers_dir|
          compile_helpers(helpers_dir)
        end

        recipes.collect do |recipe_path|
          basename    = File.basename(recipe_path).chomp(File.extname(recipe_path))
          package_dir = File.join(output_dir, basename)

          script = prepare(package_dir, script_name)
          recipe = Recipe.new(script)
          recipe.instance_eval File.read(recipe_path), recipe_path
          script.close

          if executable
            FileUtils.chmod 0744, script.path
          end

          puts package_dir
          package_dir
        end
      end

      def prepare(package_dir, script_name)
        if File.exists?(package_dir)
          unless force
            raise CommandError, "already exists: #{package_dir.inspect}"
          end
          FileUtils.rm_r(package_dir)
        end

        path = File.join(package_dir, script_name)

        FileUtils.mkdir_p(package_dir)
        FileUtils.touch(path)
        File.open(path, 'r+')
      end

      def glob_helpers(helpers_dir)
        sources = {}
        helpers = []

        Dir.glob("#{helpers_dir}/*/**/*").each do |source_file|
          next if File.directory?(source_file)
          (sources[File.dirname(source_file)] ||= []) << source_file
        end

        sources.each_pair do |dir, source_files|
          name = dir[(helpers_dir.length + 1)..-1]
          helpers << [name, source_files]
        end

        helpers.sort_by {|name, source_files| name }
      end

      def compile_helpers(helpers_dir)
        compiler = CompileHelper.new(
          :force => force,
          :quiet => true
        )

        helpers = glob_helpers(helpers_dir)
        helpers.each do |(name, sources)|
          compiler.process(name, *sources)
        end

        $LOAD_PATH.unshift compiler.output_dir
      end
    end
  end
end