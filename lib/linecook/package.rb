require 'linecook/recipe'
require 'tempfile'

module Linecook
  class Package
    class << self
      def init(env={}, cookbook=nil)
        package = new(env)
        
        if cookbook
          cookbook_config = package.cookbook_config
          package.config[MANIFEST_KEY] ||= cookbook.manifest(cookbook_config)
        end
        
        package
      end
      
      def build(path=nil, cookbook=nil)
        env = Utils.load_config(path)
        package = init(env, cookbook)
        
        package.build_all
        package.close
        package
      end
    end
    
    CONFIG_KEY          = 'linecook'
    COOKBOOK_CONFIG_KEY = 'cookbook'
    MANIFEST_KEY        = 'manifest'
    FILES_KEY           = 'files'
    TEMPLATES_KEY       = 'templates'
    RECIPES_KEY         = 'recipes'
    
    attr_reader :env
    attr_reader :tempfiles
    attr_reader :registry
    attr_reader :reverse_registry
    
    def initialize(env={})
      @env = env
      @tempfiles = []
      @registry = {}
      @reverse_registry = {}
    end
    
    def config
      env[CONFIG_KEY] ||= {}
    end
    
    def cookbook_config
      env[COOKBOOK_CONFIG_KEY] ||= {}
    end
    
    def manifest
      config[MANIFEST_KEY] ||= {}
    end
    
    def files
      normalize(FILES_KEY)
    end
    
    def templates
      normalize(TEMPLATES_KEY)
    end
    
    def recipes
      normalize(RECIPES_KEY)
    end
    
    def register(source_path, build_path=nil)
      source_path = File.expand_path(source_path)
      build_path ||= File.basename(source_path)
      
      count = 0
      registry.each_key do |path|
        if path.kind_of?(String) && path.index(build_path) == 0
          count += 1
        end
      end
      
      if count > 0
        build_path = "#{build_path}.#{count}"
      end
      
      registry[build_path] = source_path
      reverse_registry[source_path.to_sym] = build_path
      
      build_path
    end
    
    def registered?(source_path)
      source_path = File.expand_path(source_path)
      reverse_registry.has_key?(source_path.to_sym)
    end
    
    def built?(build_path)
      registry.has_key?(build_path)
    end
    
    def tempfile?(source_path)
      tempfiles.find {|tempfile| tempfile.path == source_path }
    end
    
    def tempfile(build_path)
      tempfile = Tempfile.new File.basename(build_path)
      
      register(tempfile.path, build_path)
      tempfiles << tempfile
      
      tempfile
    end
    
    def build_path(source_path)
      source_path = File.expand_path(source_path)
      reverse_registry[source_path.to_sym]
    end
    
    def source_path(build_path)
      registry[build_path]
    end
    
    def build_all
      recipes.each do |recipe_name, target_name|
        build_recipe(target_name) { evaluate(recipe_name) }
      end
      
      self
    end
    
    def recipe(target_name='recipe')
      target = tempfile(target_name)
      Recipe.new(target, self)
    end
    
    def build_recipe(target_name, content=nil, &block)
      recipe = self.recipe(target_name)
      
      recipe.instance_eval(content) if content
      recipe.instance_eval(&block)  if block
      
      recipe.close
      recipe
    end
    
    def content(build_path)
      path = source_path(build_path)
      path ? File.read(path) : nil
    end
    
    def export(dir, options={})
      close
      
      options = {
        :allow_move => true
      }.merge(options)
      
      allow_move = options[:allow_move]
      
      results = {}
      registry.each_pair do |build_path, source_path|
        target_path = File.join(dir, build_path)
        target_dir  = File.dirname(target_path)
        
        unless File.exists?(target_dir)
          FileUtils.mkdir_p(target_dir)
        end
        
        if allow_move && tempfile?(source_path)
          FileUtils.mv(source_path, target_path)
        else
          FileUtils.cp(source_path, target_path)
        end
        
        results[build_path] = target_path
      end
      results
    end
    
    def close
      tempfiles.each do |tempfile|
        tempfile.close unless tempfile.closed?
      end
      self
    end
    
    private
    
    def normalize(key)
      obj = config[key]
      
      case obj
      when Hash
        obj
        
      when nil
        config[key] = {}
        
      when Array
        hash = {}
        obj.each {|entry| hash[entry] = entry }
        config[key] = hash
      
      when String
        config[key] = obj.split(':')
        normalize(key)
      
      else
        raise "invalid #{key}: #{obj.inspect}"
      end
    end
  end
end