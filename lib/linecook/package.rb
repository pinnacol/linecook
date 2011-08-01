module Linecook
  class Package
    # The package environment
    attr_reader :env

    # A registry of (target_path, source_path) pairs recording what files
    # are included in the package.
    attr_reader :registry

    attr_reader :moveable_source_paths

    def initialize(env={})
      @env = env
      @registry = {}
      @moveable_source_paths = []
    end

    def resolve_source_path(source)
      source_path = source.respond_to?(:path) ? source.path : source
      unless source_path.kind_of?(String)
        raise "could not resolve source to a path: #{source.inspect}"
      end
      File.expand_path(source_path)
    end

    # Registers the source to the target_path.
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

    def rm(target_path)
      registry.delete(target_path)
    end

    def unregister(source)
      path = resolve_source_path(source)
      registry.delete_if do |target_path, source_path|
        path == source_path
      end
    end

    def move_on_export(source_path)
      @moveable_source_paths << source_path
    end

    def copy_on_export(source_path)
      @moveable_source_paths.delete(source_path)
    end

    # Returns the content of the source_path for target_path, as registered in
    # self.  Returns nil if the target is not registered.
    def content(target_path, length=nil, offset=nil)
      path = registry[target_path]
      path ? File.read(path, length, offset) : nil
    end

    def export(dir)
      if File.exists?(dir)
        raise "already exists: #{dir.inspect}"
      end

      registry.each_key do |target_path|
        export_path = File.join(dir, target_path)
        source_path = registry[target_path]

        if source_path == export_path
          next
        end

        export_dir = File.dirname(export_path)
        FileUtils.mkdir_p(export_dir)

        if moveable_source_paths.include?(source_path)
          FileUtils.mv(source_path, export_path)
        else
          FileUtils.cp(source_path, export_path)
        end

        registry[target_path] = export_path
      end

      registry
    end
  end
end