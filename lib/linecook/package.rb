module Linecook
  class Package
    # A string format used to determine the target_path for a given target
    # name.  The remote_dir is intended to represent the directory where a
    # package is ultimately deployed (and as such recipes can reliably
    # reference target names). When remote_dir is set to nil the target_name
    # is treated as the the target_path.
    attr_accessor :remote_dir

    # A registry of (target_name, source_path) pairs recording what files
    # are included in the package.
    attr_reader :registry

    attr_reader :moveable_source_paths

    def initialize(remote_dir=nil)
      @remote_dir = remote_dir
      @registry   = {}
      @moveable_source_paths = []
    end

    def resolve_source_path(source)
      source_path = source.respond_to?(:path) ? source.path : source
      unless source_path.kind_of?(String)
        raise "could not resolve source to a path: #{source.inspect}"
      end
      File.expand_path(source_path)
    end

    # Registers the source to the target_name.
    def add(target_name, source)
      source_path = resolve_source_path(source)

      if current = registry[target_name]
        unless current == source_path
          raise "already registered: #{target_name.inspect} (#{current.inspect})"
        end
      else
        registry[target_name] = source_path
      end

      source
    end

    def rm(target_name)
      registry.delete(target_name)
    end

    # Returns the source_path for target_name, as registered in self.  Returns
    # nil if the target is not registered.
    def source_path(target_name)
      registry[target_name]
    end

    def target_path(target_name)
      if registry.has_key?(target_name)
        remote_dir ? (remote_dir % target_name) : target_name
      else
        nil
      end
    end

    def move_on_export(source_path)
      @moveable_source_paths << source_path
    end

    def copy_on_export(source_path)
      @moveable_source_paths.delete(source_path)
    end

    # Returns the content of the source_path for target_name, as registered in
    # self.  Returns nil if the target is not registered.
    def content(target_name, length=nil, offset=nil)
      path = source_path(target_name)
      path ? File.read(path, length, offset) : nil
    end

    def export(dir)
      if File.exists?(dir)
        raise "already exists: #{dir.inspect}"
      end

      registry.each_key do |target_name|
        export_path = File.join(dir, target_name)
        source_path = registry[target_name]

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

        registry[target_name] = export_path
      end

      registry
    end
  end
end