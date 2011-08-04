module Linecook
  module Utils
    module_function

    def deep_merge(a, b)
      b.each_pair do |key, current|
        previous = a[key]
        a[key] = deep_merge?(previous, current) ? deep_merge(previous, current) : current
      end

      a
    end

    def deep_merge?(previous, current)
      current.kind_of?(Hash) && previous.kind_of?(Hash)
    end

    def camelize(str)
      str.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
    end

    def underscore(str)
      str.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
    end

    def constantize(const_name)
      constants = camelize(const_name).split(/::/)

      const = Object
      while name = constants.shift
        const = const.const_get(name)
      end

      const
    end

    if Dir.pwd[0] == ?/
      def absolute?(path)
        path[0] == ?/
      end
    else
      def absolute?(path)
        path =~ /^[A-z]:\//
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