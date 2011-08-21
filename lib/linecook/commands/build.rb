require 'linecook/commands/compile'

module Linecook
  module Commands
    # ::desc package recipes
    #
    # Builds a list of 'package' recipes into a list of packages.  Packages
    # are exported to the working directory based on the basename of the
    # recipe. Recipes are not added to the package by default (unlike compile)
    # but they are automatically configured with a package file with the same
    # basename, if it exists.  This type of workflow is possible:
    #
    #   $ echo "capture_path('run', 'echo ' + attrs['msg'])" > recipe.rb 
    #   $ echo "msg: hello world" > recipe.yml
    #   $ linecook build recipe.rb
    #   /path/to/pwd/recipe
    #   $ sh recipe/run
    #   hello world
    #
    # The base export dir and package config dir can both be set with options.
    # The final package dir for each recipe is printed to stdout, as shown
    # above.
    #
    # If more control over the mapping of recipes to packages is needed, then
    # provide a comma-separated string specifying
    # 'package_file,recipe_file,export_dir'. Non-absolute file paths may be
    # provided, in which case the package file is resolved relative to the
    # package config dir, the recipe is looked up by the cookbook, and the
    # export dir is resolved relative to the export dir.
    #
    # Providing '-' as an input will cause stdin to be read for additional
    # inputs.  In that way a CSV file can serve as a manifest for the packages
    # created by this command.
    #
    class Build < Compile
      pwd = Dir.pwd
      config :input_dir, pwd                     # -i DIRECTORY : package config dir
      config :output_dir, pwd                    # -o DIRECTORY : base export dir
      undef_config :package_file

      def input_dir=(input)
        @package_finder = nil
        super(input)
      end

      def package_finder
        @package_finder ||= Cookbook.new(:package_file => [input_dir])
      end

      def package_file(package_name)
        package_finder._find_(:package_file, package_name, ['.yml'])
      end

      def process(*recipes)
        helper_dirs.each do |helpers_dir|
          compile_helpers(helpers_dir)
        end

        each_spec(recipes) do |package_name, recipe_name, export_name|
          export_dir = File.expand_path(export_name, output_dir)
          if File.exists?(export_dir)
            unless force
              raise CommandError, "already exists: #{export_dir.inspect}"
            end
            FileUtils.rm_r(export_dir)
          end

          package  = Package.new(load_env(package_file(package_name)))
          cookbook = Cookbook.new(*cookbook_path)
          
          recipe   = Recipe.new(package, cookbook)
          recipe.helper *helpers
          recipe._compile_ recipe_name

          package.export(export_dir)
          puts export_dir
        end
      end

      def each_line(lines)
        lines.each do |line|
          if line == '-'
            while line = gets
              yield line
            end
          else
            yield line
          end
        end
      end

      def each_spec(lines)
        each_line(lines) do |line|
          yield *parse_spec(line)
        end
      end

      def parse_spec(spec)
        fields = []
        CSV.parse_row(spec, 0, fields)

        case fields.length
        when 1  # short form
          recipe_path = fields.at(0)
          export_name = File.basename(recipe_path).chomp(File.extname(recipe_path))
          ["#{export_name}.yml", recipe_path, export_name]
        when 3  # long form
          fields
        else
          raise "invalid spec: #{spec.inspect}"
        end
      end
    end
  end
end