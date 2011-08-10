require 'tempfile'
require 'stringio'

module Linecook
  class Package
    # The package environment
    attr_reader :env

    # A registry of (target_path, source) pairs recording what is included in
    # the package.
    attr_reader :registry

    # A hash of the default export options.  These are merged with the export
    # opts for a given target path.
    attr_reader :default_export_options

    # A hash of (target_path, Hash) pairs identifing export options for a
    # target path.  See on_export.
    attr_reader :export_option_overrides

    # A hash of callbacks registered with self
    attr_reader :callbacks

    def initialize(env={})
      @env = env
      @registry = {}
      @default_export_options  = {}
      @export_option_overrides = {}
      @callbacks = {}
    end

    # Resolves a source (ex a String, StringIO, or Tempfile) to a source path.
    # Non-String sources are converted to sources by calling`source.path`.
    # Returns the expanded source path, or nil if the source is nil.
    def resolve_source_path(source)
      if source.nil?
        return nil
      end

      unless source_path?(source)
        source = source.path
      end

      File.expand_path(source)
    end

    # Registers the source to the target_path.  Raises an error if a different
    # source is already registerd to the target_path.
    def register(target_path, source, options={})
      if current = source_path(target_path)
        unless current == resolve_source_path(source)
          raise "already registered: #{target_path.inspect} (#{current.inspect})"
        end
      end

      if source_path?(source)
        source = File.expand_path(source)
      end

      registry[target_path] = source
      on_export(target_path, options)

      source
    end

    # Removes all target paths that reference a source in the registry.
    def unregister(source)
      source_path = resolve_source_path(source)
      registry.delete_if do |target_path, current|
        source_path == resolve_source_path(current)
      end
    end

    # Generates a tempfile for the target path and registers it to self.
    # Returns the open tempfile.
    def add(target_path, options={})
      source  = Tempfile.new File.basename(target_path)
      options = {:move => true}.merge(options)
      register target_path, source, options
    end

    # Removes a target path from the registry.  Returns the source if one was
    # registered.
    def rm(target_path)
      registry.delete(target_path)
    end

    # Returns the source path registered to target path, or nil if the target
    # path is not registered.
    def source_path(target_path)
      resolve_source_path registry[target_path]
    end

    # Returns an array of target paths that register the source.
    def target_paths(source)
      source_path = resolve_source_path(source)

      target_paths = []
      registry.delete_if do |target_path, current|
        if source_path == resolve_source_path(current)
          target_paths << target_path
        end
      end

      target_paths
    end

    # Returns the content for a target, as registered in self.  Returns nil if
    # the target is not registered.
    def content(target_path, length=nil, offset=nil)
      source = registry[target_path]

      if source.nil?
        return nil
      end

      unless source_path?(source)
        source.flush unless source.closed?
      end

      source_path = resolve_source_path(source)
      File.read(source_path, length, offset)
    end

    def callback(name)
      callbacks[name] ||= StringIO.new
    end

    # Increments target_path until an unregistered path is found and returns
    # the result.
    def next_target_path(target_path='file')
      count = 0
      registry.each_key do |current|
        if current.index(target_path) == 0
          count += 1
        end
      end

      if count > 0
        target_path = "#{target_path}.#{count}"
      end

      target_path
    end

    # Closes all open sources in the registry and returns self.
    def close
      registry.each_value do |source|
        unless source_path?(source)
          source.close unless source.closed?
        end
      end
      self
    end

    # Sets export options for the target path.  Available options include:
    #
    #   Option    Description
    #   :move     When set to true the target source will be moved into place
    #             rather than copied (the default)
    #   :mode     Sets the mode of the target to the option value
    #
    def on_export(target_path, options={})
      export_option_overrides[target_path] = options
    end

    # Returns a hash of the export options for a target path, equivalent to
    # the default_export_options merged with any overriding options set for
    # the target.
    def export_options(target_path)
      overrides = export_option_overrides[target_path] || {}
      default_export_options.merge(overrides)
    end

    def export(dir)
      close

      registry.each_pair do |target_path, source|
        export_path = File.join(dir, target_path)
        source_path = resolve_source_path(source)
        options     = export_options(target_path)

        if source_path != export_path
          export_dir = File.dirname(export_path)
          FileUtils.mkdir_p(export_dir)

          if options[:move]
            FileUtils.mv(source_path, export_path)
          else
            FileUtils.cp(source_path, export_path)
          end
        end

        if mode = options[:mode]
          FileUtils.chmod(mode, export_path)
        end

        registry[target_path] = export_path
      end

      registry
    end

    private

    # helper to determine if a source is indeed the path to a source file (ie
    # a String) or if it must be treated as some type of IO.
    def source_path?(source) # :nodoc:
      source.kind_of?(String)
    end
  end
end