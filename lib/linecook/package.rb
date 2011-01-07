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
        
        package.build
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
    
    def register!(source_path, target_path)
      source_path = File.expand_path(source_path)
      
      if registered?(source_path)
        raise "already registered: #{source_path.inspect}"
      end
      
      registry[target_path] = source_path
      reverse_registry[source_path] = target_path
      
      target_path
    end
    
    def register(source_path, target_path=nil)
      source_path = File.expand_path(source_path)
      target_path ||= File.basename(source_path)
      
      count = 0
      registry.each_key do |path|
        if path.kind_of?(String) && path.index(target_path) == 0
          count += 1
        end
      end
      
      if count > 0
        target_path = "#{target_path}.#{count}"
      end
      
      register!(source_path, target_path)
    end
    
    def registered?(source_path)
      source_path = File.expand_path(source_path)
      reverse_registry.has_key?(source_path)
    end
    
    def register_path(target_path)
      registry[target_path]
    end
    
    def source?(path)
      manifest.has_key?(path)
    end
    
    def source_path(*relative_path)
      path = File.join(*relative_path)
      manifest[path] or raise "no such file in manifest: #{path.inspect}"
    end
    
    def target?(target_path)
      registry.has_key?(target_path)
    end
    
    def target_path(source_path)
      source_path = File.expand_path(source_path)
      reverse_registry[source_path]
    end
    
    def tempfile?(source_path)
      tempfiles.find {|tempfile| tempfile.path == source_path }
    end
    
    def tempfile(target_path)
      tempfile = Tempfile.new File.basename(target_path)
      
      register(tempfile.path, target_path)
      tempfiles << tempfile
      
      tempfile
    end
    
    def tempfile!(target_path)
      tempfile = Tempfile.new File.basename(target_path)
      
      register!(tempfile.path, target_path)
      tempfiles << tempfile
      
      tempfile
    end
    
    def recipe(target_path='recipe')
      target = tempfile(target_path)
      Recipe.new(target, self)
    end
    
    def build_file(file_name, target_path)
      register!(source_path('files', file_name), target_path)
    end
    
    def build_template(template_name, target_path)
      source = source_path('templates', "#{template_name}.erb")
      
      target = tempfile!(target_path)
      target << Template.build(File.read(source), env, source)
      
      target.close
      target
    end
    
    def build_recipe(target_path='recipe', content=nil, &block)
      recipe = self.recipe(target_path)
      
      recipe.instance_eval(content) if content
      recipe.instance_eval(&block)  if block
      
      recipe.close
      recipe
    end
    
    def build
      files.each do |file_name, target_path|
        build_file(file_name, target_path)
      end
      
      templates.each do |template_name, target_path|
        build_template(template_name, target_path)
      end
      
      recipes.each do |recipe_name, target_path|
        build_recipe(target_path) { evaluate(recipe_name) }
      end
      
      self
    end
    
    def content(target_path)
      path = register_path(target_path)
      path ? File.read(path) : nil
    end
    
    def close
      tempfiles.each do |tempfile|
        tempfile.close unless tempfile.closed?
      end
      self
    end
    
    def export(dir, options={})
      close
      
      options = {
        :allow_move => true
      }.merge(options)
      
      allow_move = options[:allow_move]
      
      registry.each_key do |target_path|
        export_path = File.join(dir, target_path)
        export_dir  = File.dirname(export_path)
        
        unless File.exists?(export_dir)
          FileUtils.mkdir_p(export_dir)
        end
        
        source_path = registry[target_path]
        
        if allow_move && tempfile?(source_path)
          FileUtils.mv(source_path, export_path)
        else
          FileUtils.cp(source_path, export_path)
        end
        
        registry[target_path] = export_path
      end
      
      tempfiles.clear
      registry
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