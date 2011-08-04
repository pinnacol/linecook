module Linecook
  class Cookbook
    DEFAULT_PROJECT_PATHS = {
      :attributes => ['attributes'],
      :files      => ['files'],
      :templates  => ['templates'],
      :recipes    => ['recipes']
    }

    attr_reader :paths

    def initialize(*project_dirs)
      @paths = []
      project_dirs.each do |dir|
        case dir
        when String then add(dir)
        when Hash   then add('.', dir)
        else add(*dir)
        end
      end
    end

    # Returns an array of directories comprising the path for type.
    def path(type)
      paths.collect do |dir|
        if dir.kind_of?(String)
          File.join(dir, type.to_s)
        else
          dir[type]
        end
      end.compact
    end

    def resolve(dir, mappings=nil)
      case mappings
      when nil
        File.expand_path(dir)
      when Hash
        expand_hash(dir, mappings)
      when String
        cookbook_file = File.expand_path(mappings, dir)
        mappings = File.exists?(cookbook_file) ? YAML.load_file(cookbook_file) : nil
        mappings ? expand_hash(dir, mappings) : File.expand_path(dir)
      else
        raise ArgumentError, "invalid mappings: #{mappings.inspect} (must be String, Hash, or nil)"
      end
    end

    def expand_hash(dir, mappings)
      path_hash = {}
      mappings.each_pair do |type, path|
        path_hash[type.to_sym] = File.expand_path(path, dir)
      end
      path_hash
    end

    def add(dir, mappings=nil)
      paths << resolve(dir, mappings) 
    end

    def rm(dir, mappings=nil)
      paths.delete resolve(dir, mappings)
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

    if Dir.pwd[0] == ?/
      def absolute?(path)
        path && path[0] == ?/
      end
    else
      def absolute?(path)
        path && path =~ /^[A-z]:\//
      end
    end

    def subpath?(dir, full_path)
      full_path.index(dir) == 0
    end

    def each_full_path(dir, path, extnames=nil)
      full_path = File.expand_path(path, dir)
      yield full_path

      extnames.each do |extname|
        full_path = File.expand_path("#{path}#{extname}", dir)
        yield full_path
      end if extnames
    end
  end
end