require 'linecook/utils'

module Linecook
  class Cookbook
    class << self
      def config_file(dir)
        Dir.glob(File.join(dir, '{Cc}ookbook')).first
      end
        
      def init(dir)
        path   = config_file(dir)
        config = path ? YAML.load_file(path) : nil
        new(dir, config || {})
      end
      
      def gems
        return [] unless Object.const_defined?(:Gem)
        
        Gem.source_index.latest_specs.select do |spec|
          config_file(spec.full_gem_path) != nil
        end.collect do |spec|
          spec.name
        end
      end
    end
    
    include Utils
    
    DEFAULT_NAMESPACE = 'linebook'
    DEFAULT_PATTERNS = [
      ['', File.join('attributes', '**', '*.rb')],
      ['', File.join('files',      '**', '*')],
      ['', File.join('recipes',    '**', '*.rb')],
      ['', File.join('templates',  '**', '*.erb')]
    ]
    
    attr_reader :dir
    attr_reader :config
    
    def initialize(dir = Dir.pwd, config = {})
      @dir = dir
      @config = {
         'patterns' => DEFAULT_PATTERNS,
         'paths' => ['.'],
         'gems'  => self.class.gems,
         'namespace' => DEFAULT_NAMESPACE
       }.merge(config)
    end
    
    def namespace
      config['namespace']
    end
    
    def manifest
      @manifest ||= __manifest(config)
    end
    
    def each_helper
      helpers_dir = File.expand_path('helpers', dir)
      lib_dir = File.expand_path('lib', dir)
      
      sources = {}
      Dir.glob("#{helpers_dir}/**/*").each do |source|
        next if File.directory?(source)
        (sources[File.dirname(source)] ||= []) << source
      end
      
      sources.each_pair do |dir, sources|
        name = dir[(helpers_dir.length+1)..-1]
        const_path = name ? File.join(namespace, name) : namespace
        
        target  = File.join(lib_dir, "#{const_path}.rb")
        sources = sources + [dir]
        
        yield sources, target, camelize(const_path)
      end
    end
    
    def each_script
      scripts_dir = File.expand_path('scripts', dir)
      
      Dir.glob("#{scripts_dir}/*.yml").each do |source|
        name   = File.basename(source).chomp('.yml')
        target = File.join(scripts_dir, name)
        
        yield source, target, name
      end
    end
    
    # Generate the manifest from a config.
    def __manifest(config)
      manifest  = {}
      overrides = config['manifest'] || {}

      __paths(config).each do |(dir, base, pattern)|
        base_path = File.expand_path(File.join(dir, base))
        start     = base_path.length + 1

        Dir.glob(File.join(base_path, pattern)).each do |path|
          rel_path = path[start, path.length - start]
          manifest[rel_path] = path
        end
      end

      manifest.merge!(overrides)
      manifest
    end

    # Parses config to return an array of [dir, base, pattern] paths.
    def __paths(config)
      paths    = __parse_paths(config['paths'] || [])
      gems     = __parse_gems(config['gems'] || [])
      patterns = __parse_patterns(config['patterns'] || [])

      __combine(patterns, gems + paths)
    end

    # Parses the 'paths' config by splitting strings into an array.
    def __parse_paths(paths)
      paths.kind_of?(String) ? __split(paths) : paths
    end

    # Parses the 'gems' config by splitting strings into an array, and resolving
    # each name to the corresponding full_gem_path.
    def __parse_gems(gems)
      gems = gems.kind_of?(String) ? __split(gems) : gems

      unless gems.empty?
        specs = __latest_specs
        gems  = gems.collect do |name| 
          spec = specs[name] or raise "no such gem: #{name.inspect}"
          spec.full_gem_path
        end
      end

      gems
    end

    # Parses the 'patterns' config by splitting string patterns, flattening hash
    # patterns, and then dividing each pattern into a [base, pattern] pair.
    def __parse_patterns(patterns)
      case patterns
      when String then __split(patterns)
      when Hash   then __flatten(patterns)
      else patterns
      end.collect {|pattern| __divide(pattern) }
    end

    # Splits the string into an array along colons.  Returns non-string inputs.
    def __split(str)
      str.kind_of?(String) ? str.split(':') : str
    end

    # Divides a string pattern into a [base, pattern] pair.  Returns non-string
    # patterns.
    def __divide(pattern)
      pattern.kind_of?(String) ? pattern.split('/', 2) : pattern
    end

    # Flattens a patterns hash into an array of patterns.
    def __flatten(hash)
      patterns = []
      hash.each_pair do |base, value|
        __split(value).each do |pattern|
          patterns << [base, pattern]
        end
      end
      patterns
    end

    # Combines patterns and paths into [path, base, pattern] arrays.
    def __combine(patterns, paths)
      combinations = []
      paths.each do |path|
        if path.kind_of?(String)
          patterns.each do |(base, pattern)|
            combinations << [path, base, pattern]
          end
        else
          combinations << path
        end
      end
      combinations
    end

    # Returns a hash of the latest specs available in Gem.source_index.
    def __latest_specs
      latest = {}
      Gem.source_index.latest_specs.each do |spec|
        latest[spec.name] = spec
      end
      latest
    end
  end
end