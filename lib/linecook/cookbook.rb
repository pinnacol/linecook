require 'linecook/utils'

module Linecook
  class Cookbook
    include Utils

    # A hash of (type, [paths]) pairs tracking lookup paths of a given type.
    attr_reader :paths

    def initialize(paths={})
      @paths = paths
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
  end
end