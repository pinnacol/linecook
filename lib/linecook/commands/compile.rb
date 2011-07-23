require 'fileutils'
require 'linecook/recipe'

module Linecook
  module Commands
    # ::desc compile recipes, helpers, packages
    class Compile < Command
      config_type(:path) do |input|
        File.expand_path(input)
      end

      config :output_dir, '.', :type => :path    # -o : specify the output dir
      config :script_name, 'run'                 # -s : specify the script name
      config :load_path, [], :type => :path      # -I : prepend to LOAD_PATH

      def load_path=(paths)
        (@load_path ||= []).each do |path|
          $LOAD_PATH.delete(path)
        end

        @load_path = paths

        @load_path.reverse_each do |path|
          $LOAD_PATH.unshift(path)
        end
      end

      def process(recipe_path)
        basename    = File.basename(recipe_path).chomp(File.extname(recipe_path))
        package_dir = File.join(output_dir, basename)
        script_path = File.join(package_dir, script_name)

        script = prepare(script_path)
        recipe = Recipe.new(script)
        recipe.instance_eval File.read(recipe_path), recipe_path
        script.close
        FileUtils.chmod 0744, script_path

        puts package_dir
        package_dir
      end

      def prepare(path)
        FileUtils.mkdir_p File.dirname(path)
        File.open(path, 'w')
      end
    end
  end
end