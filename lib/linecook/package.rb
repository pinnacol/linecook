module Linecook
  class Package
    # The package environment
    attr_reader :env

    # A registry of (target_path, source_path) pairs recording what files
    # are included in the package.
    attr_reader :registry

    # A hash of (source_path, Hash) pairs identifing export options for a
    # source path, for example a flag to move rather than copy the file.
    attr_reader :export_opts

    def initialize(env={})
      @env = env
      @registry = {}
      @export_opts = Hash.new({})
    end

    # Resolves a source (ex a StringIO or Tempfile) to a source path by
    # calling `source.path`, which should return a String pathname. If the
    # source does not respond to path, then the source should be the pathname.
    # Returns the expanded source path.
    def resolve_source_path(source)
      source_path = source.respond_to?(:path) ? source.path : source
      unless source_path.kind_of?(String)
        raise "could not resolve source to a path: #{source.inspect}"
      end
      File.expand_path(source_path)
    end

    # Registers the source to the target_path.  The source is first resolved
    # to a source path using resolve_source_path.
    def add(target_path, source)
      source_path = resolve_source_path(source)

      if current = registry[target_path]
        unless current == source_path
          raise "already registered: #{target_path.inspect} (#{current.inspect})"
        end
      else
        registry[target_path] = source_path
      end

      source
    end

    # Removes a target path from the registry.
    def rm(target_path)
      registry.delete(target_path)
    end

    # Removes all target paths that reference a source in the registry.  The
    # source is resolved to a source path using resolve_source_path in the
    # same way as add.
    def unregister(source)
      path = resolve_source_path(source)
      registry.delete_if do |target_path, source_path|
        path == source_path
      end
    end

    # Returns the content for a target, as registered in self.  Returns nil if
    # the target is not registered.
    def content(target_path, length=nil, offset=nil)
      path = registry[target_path]
      path ? File.read(path, length, offset) : nil
    end

    # Sets export options for the source.  Available options include:
    #
    #   Option    Description
    #   :move     When set to true the source will be moved into place rather
    #             than copied (the default)
    #   :mode     Sets the mode of the exported file to the option value
    #
    def on_export(source, options={})
      source_path = resolve_source_path(source)
      export_opts[source_path] = options
    end

    def export(dir)
      if File.exists?(dir)
        raise "already exists: #{dir.inspect}"
      end

      registry.each_key do |target_path|
        export_path = File.join(dir, target_path)
        source_path = registry[target_path]
        options     = export_opts[source_path]

        if source_path == export_path
          next
        end

        export_dir = File.dirname(export_path)
        FileUtils.mkdir_p(export_dir)

        if options[:move]
          FileUtils.mv(source_path, export_path)
        else
          FileUtils.cp(source_path, export_path)
        end

        if mode = options[:mode]
          FileUtils.chmod(mode, export_path)
        end

        registry[target_path] = export_path
      end

      registry
    end
  end
end