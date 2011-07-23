require 'fileutils'
require 'linecook/recipe'

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

      config :output_dir, '.'      # -o DIRECTORY : specify the output dir
      config :script_name, 'run'   # -s NAME : specify the script name
      config :executable, false    # -x : make the script executable

      def output_dir=(input)
        @output_dir = File.expand_path(input)
      end

      def process(*recipes)
        recipes.collect do |recipe_path|
          basename    = File.basename(recipe_path).chomp(File.extname(recipe_path))
          package_dir = File.join(output_dir, basename)
          script_path = File.join(package_dir, script_name)

          script = prepare(script_path)
          recipe = Recipe.new(script)
          recipe.instance_eval File.read(recipe_path), recipe_path
          script.close

          if executable
            FileUtils.chmod 0744, script_path
          end

          puts package_dir
          package_dir
        end
      end

      def prepare(path)
        FileUtils.mkdir_p File.dirname(path)
        File.open(path, 'w')
      end
    end
  end
end