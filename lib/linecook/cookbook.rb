require 'linecook/utils'

module Linecook
  class Cookbook
    include Utils

    DEFAULT_PROJECT_PATHS = {
      :attributes => ['attributes'],
      :files      => ['files'],
      :templates  => ['templates'],
      :recipes    => ['recipes']
    }

    # A hash of (type, [paths]) pairs tracking lookup paths of a given type.
    attr_reader :paths

    attr_reader :project_paths

    def initialize(paths={}, project_paths=DEFAULT_PROJECT_PATHS)
      @paths = paths
      @project_paths = project_paths
    end

    # Returns an array of directories comprising the path for type.
    def path(type)
      paths[type] ||= []
    end

    # Expands and pushes the directory onto the path for type.
    def add(type, dir)
      path(type).push File.expand_path(dir)
    end

    # Removes the directory from the path for type.
    def rm(type, dir)
      path(type).delete File.expand_path(dir)
    end

    def add_project_dir(dir, cookbook_file='cookbook.yml')
      each_project_path(dir, cookbook_file) do |type, path|
        add type, path
      end
      add :projects, dir
    end

    def rm_project_dir(dir, cookbook_file='cookbook.yml')
      each_project_path(dir, cookbook_file) do |type, path|
        rm type, path
      end
      rm :projects, dir
    end

    def bulk_add(paths)
      each_bulk_path(paths) do |type, path|
        add type, path
      end
    end

    def bulk_rm(paths)
      each_bulk_path(paths) do |type, path|
        rm type, path
      end
    end

    # Searches for a file by expanding filename vs each directory in the path
    # for type. The first existing full path is returned.  If an array of
    # extnames is provided, then each extname is tried for each directory,
    # much as with Kernal.require. Absolute paths that exists are returned
    # directly.  Returns nil if no file can be found.
    def find(type, filename, extnames=nil)
      if absolute?(filename)
        return File.exists?(filename) ? filename : nil
      end

      path(type).each do |dir|
        each_full_path(dir, filename, extnames) do |full_path|
          if File.exists?(full_path) && subpath?(dir, full_path)
            return full_path
          end
        end
      end

      nil
    end

    protected

    def arrayify(obj)
      obj.kind_of?(Array) ? obj : [obj]
    end
    
    def each_project_path(dir, cookbook_file)
      cookbook_file = File.expand_path(cookbook_file, dir)
      paths = File.exists?(cookbook_file) ? YAML.load_file(cookbook_file) : nil
      paths ||= project_paths
      
      paths.each_pair do |type, relative_paths|
        type = type.to_sym
        arrayify(relative_paths).each do |relative_path|
          yield type, File.join(dir, relative_path)
        end
      end
    end

    def each_bulk_path(paths)
      paths.each_pair do |type, dirs|
        arrayify(dirs).each do |dir|
          yield type, dir
        end
      end
    end
  end
end