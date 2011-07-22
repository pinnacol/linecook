require 'fileutils'
require 'linecook/recipe'

module Linecook
  module Commands
    # ::desc compile recipes, helpers, packages
    class Compile < Command
      config :default_package_dir, nil  # -d, --package-dir : specify the package dir
      config :script_name, 'run'        # -s : specify the script name

      def process(recipe_path)
        package_dir = guess_package_dir(recipe_path)
        script_path = File.join(package_dir, script_name)

        script = prepare(script_path)
        recipe = Recipe.new(script)
        recipe.instance_eval File.read(recipe_path), recipe_path
        script.close
        FileUtils.chmod 0744, script_path

        puts package_dir
        package_dir
      end
      
      def guess_package_dir(recipe_path)
        extname = File.extname(recipe_path)

        case
        when default_package_dir
          basename = File.basename(recipe_path).chomp(extname)
          File.join(default_package_dir, basename)
        when extname.empty?
          "#{recipe_path}.d"
        else
          recipe_path.chomp(extname)
        end
      end

      def prepare(path)
        dir = File.dirname(path)
        unless File.exists?(dir)
          FileUtils.mkdir_p(dir)
        end

        File.open(path, 'w')
      end
    end
  end
end