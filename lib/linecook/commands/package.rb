require 'linecook/commands/compile'

module Linecook
  module Commands
    # ::desc compile recipes, helpers, packages
    class Package < Compile
      undef_config :package_file

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

          package_file = find(input_dir, package_name)
          package  = Linecook::Package.new(load_env(package_file))
          cookbook = Linecook::Cookbook.new(*cookbook_path)
          
          recipe   = Recipe.new(package, cookbook)
          recipe.helper *helpers
          recipe._compile_ recipe_name

          package.export(export_dir)
          puts export_dir
        end
      end

      def find(input_dir, package_name)
        if File.exists?(package_name)
          package_name
        else
          File.expand_path(package_name, input_dir)
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
          base = fields.at(0)
          [guess_package_name(base), guess_recipe_name(base), guess_export_name(base)]
        when 3  # long form
          fields
        else
          raise "invalid spec: #{spec.inspect}"
        end
      end

      def guess_package_name(base)
        extname = File.extname(base)
        case extname
        when '.yml' then base
        else "#{base.chomp(extname)}.yml"
        end
      end
      
      def guess_recipe_name(base)
        extname = File.extname(base)
        case extname
        when '.rb' then base
        else "#{base.chomp(extname)}.rb"
        end
      end
      
      def guess_export_name(base)
        extname = File.extname(base)
        File.basename(base).chomp(extname)
      end

      def load_env(package_file)
        package_file && File.exists?(package_file) ? YAML.load_file(package_file) : {}
      end
    end
  end
end