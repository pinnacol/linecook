module Linecook
  class Cookbook
    class << self
      attr_writer :default_path_map
      def default_path_map
        @default_path_map ||= {
          :attributes => ['attributes'],
          :files      => ['files'],
          :templates  => ['templates'],
          :recipes    => ['recipes']
        }
      end
    end

    attr_reader :registry

    def initialize(*project_dirs)
      @registry = {}
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
      registry[type] || []
    end

    def add(dir, path_map=nil)
      resolve_path_map(dir, path_map).each_pair do |type, paths|
        (registry[type] ||= []).concat(paths)
      end
    end

    def rm(dir, path_map=nil)
      resolve_path_map(dir, path_map).each_pair do |type, paths|
        if current = registry[type]
          current = current - paths
          if current.empty?
            registry.delete(type)
          else
            registry[type] = current
          end
        end
      end
    end

    # Same as find but returns nil if no file can be found.
    def _find_(type, filename, extnames=nil)
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

    # Searches for a file by expanding filename vs each directory in the path
    # for type. The first existing full path is returned.  If an array of
    # extnames is provided, then each extname is tried for each directory,
    # much as with Kernal.require. Absolute paths that exists are returned
    # directly.  Raises an error if the file cannot be found.
    def find(type, source_name, extnames=nil)
      _find_(type, source_name, extnames) or begin
        if absolute?(source_name)
          raise "no such file: #{source_name.inspect}"
        else
          try_string = try_extnames?(source_name, extnames) ? " (tried #{extnames.join(', ')})" : nil
          raise "could not find file: #{source_name.inspect}#{try_string}"
        end
      end
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

    def try_extnames?(path, extnames)
      extnames && File.extname(path).empty?
    end

    def each_full_path(dir, path, extnames=nil)
      full_path = File.expand_path(path, dir)
      yield full_path

      if try_extnames?(path, extnames)
        extnames.each do |extname|
          full_path = File.expand_path("#{path}#{extname}", dir)
          yield full_path
        end
      end
    end

    def resolve_path_map(dir, path_map=nil)
      path_map ||= self.class.default_path_map

      case path_map
      when Hash
        expand_path_map(dir, path_map)
      when String
        cookbook_file = File.expand_path(path_map, dir)
        path_map = File.exists?(cookbook_file) ? YAML.load_file(cookbook_file) : nil
        path_map ||= self.class.default_path_map

        unless path_map.kind_of?(Hash)
          raise "could not load path map: #{cookbook_file.inspect} (does not load a Hash)"
        end

        expand_path_map(dir, path_map)
      else
        raise "could not resolve path map: #{path_map.inspect} (must be String, Hash, or nil)"
      end
    end

    def expand_path_map(dir, path_map)
      results = Hash.new {|hash, key| hash[key] = [] }

      path_map.each_pair do |type, paths|
        unless paths.kind_of?(Array)
          paths = [paths]
        end
        paths.each do |path|
          results[type.to_sym] << File.expand_path(path, dir)
        end
      end
      results
    end
  end
end