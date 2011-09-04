require 'linecook/commands/compile'

module Linecook
  module Commands
    # ::desc build packages
    #
    # Builds a list of 'package' recipes into packages.  Packages are exported
    # to a directory named like the recipe. Build prints the package dir for
    # each recipe to stdout.
    #
    # Recipes are added to the package as the 'run' executable and they are
    # automatically configured with a package file corresponding to the
    # recipe, if it exists.
    #
    # For example:
    #
    #   $ echo "write 'echo ' + attrs['msg']" > recipe.rb
    #   $ echo "msg: hello world" > recipe.yml
    #   $ linecook build recipe.rb
    #   /path/to/pwd/recipe
    #   $ /path/to/pwd/recipe/run
    #   hello world
    #
    # The input directory containing the package files and the output
    # directory for the packages may be specified with options.
    #
    # == Package Specs
    #
    # Package specs can be provided instead of recipes.  Specs are
    # comma-separated strings like 'package_file,recipe_file,export_dir' that
    # allow full control over the building of packages. Package files
    #
    # For example:
    #
    #   $ echo "write 'echo ' + attrs['msg']" > recipe.rb
    #   $ echo "msg: hello world" > input.yml
    #   $ linecook build input.yml,recipe.rb,output
    #   /path/to/pwd/output
    #   $ /path/to/pwd/output/run
    #   hello world
    #
    # Providing '-' as an input will cause stdin to be read for additional
    # inputs.  In that way a CSV file can serve as a manifest for the packages
    # built by this command.
    #
    class Build < Compile
      undef_config :package_file

      def input_dir=(input)
        @package_finder = nil
        super(input)
      end

      def process(*recipes)
        helper_dirs.each do |helpers_dir|
          compile_helpers(helpers_dir)
        end

        each_spec(recipes) do |package_file, recipe_file, export_dir|
          export_dir = File.expand_path(export_dir, output_dir)
          if File.exists?(export_dir)
            unless force
              raise CommandError, "already exists: #{export_dir.inspect}"
            end
            FileUtils.rm_r(export_dir)
          end

          package_file = File.expand_path(package_file, input_dir)
          package  = Package.new(load_env(package_file))
          cookbook = Cookbook.new(*cookbook_path)

          recipe_file = File.expand_path(recipe_file)
          target   = package.add('run', :mode => 0744)
          recipe   = Recipe.new(package, cookbook, target)
          recipe._compile_ recipe_file

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
        fields = CSV.parse_line(spec)

        case fields.length
        when 1  # short form
          recipe_path = fields.at(0)
          base_name = File.basename(recipe_path).chomp('.rb')
          ["#{base_name}.yml", recipe_path, base_name]
        when 3  # long form
          fields
        else
          raise "invalid spec: #{spec.inspect}"
        end
      end
    end
  end
end