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
    
    # Registers the source_path to target_path in the registry and
    # revese_registry.  Raises an error if the source_path is already
    # registered.
    def register!(target_path, source_path)
      source_path = File.expand_path(source_path)
      
      if registered_target?(target_path) && source_path(target_path) != source_path
        raise "already registered: #{target_path.inspect}"
      end
      
      registry[target_path] = source_path
      reverse_registry[source_path] = target_path
      
      target_path
    end
    
    # Registers the source_path to target_path in the registry and
    # revese_registry.  Increments and returns the new target_path if the
    # target_path is already a registered target.
    def register(target_path, source_path)
      source_path = File.expand_path(source_path)
      
      count = 0
      registry.each_key do |path|
        if path.kind_of?(String) && path.index(target_path) == 0
          count += 1
        end
      end
      
      if count > 0
        target_path = "#{target_path}.#{count}"
      end
      
      register!(target_path, source_path)
    end
    
    # Returns true if the target_path is registered.
    def registered_target?(target_path)
      registry.has_key?(target_path)
    end
    
    # Returns true if the source_path is registered.
    def registered_source?(source_path)
      source_path = File.expand_path(source_path)
      reverse_registry.has_key?(source_path)
    end
    
    # Returns the source_path registered to target_path.
    def source_path(target_path)
      registry[target_path]
    end
    
    # Returns the latest target_path registered to source_path.
    def target_path(source_path)
      source_path = File.expand_path(source_path)
      reverse_registry[source_path]
    end
    
    # Returns true if there is a path for the specified resource in manifest.
    def resource?(*segments)
      manifest.has_key? File.join(*segments)
    end
    
    # Returns the path to the resource in manfiest.  Raises an error if there
    # is no such resource.
    def resource_path(*segments)
      path = File.join(*segments)
      manifest[path] or raise "no such resource in manifest: #{path.inspect}"
    end
    
    # Returns the resource_path the named attributes file (adds '.rb' extname).
    def attributes_path(attributes_name)
      resource_path('attributes', "#{attributes_name}.rb")
    end
    
    # Returns the resource_path the named file.
    def file_path(file_name)
      resource_path('files', file_name)
    end
    
    # Returns the resource_path the named template file (adds '.erb' extname).
    def template_path(template_name)
      resource_path('templates', "#{template_name}.erb")
    end
    
    # Returns the resource_path the named recipe file (adds '.rb' extname).
    def recipe_path(recipe_name)
      resource_path('recipes', "#{recipe_name}.rb")
    end
    
    # Generates a tempfile for the target path and registers it with self. As
    # with register, the target_path will be incremented as needed.  Returns
    # the open tempfile.
    def tempfile(target_path='tempfile')
      tempfile = Tempfile.new File.basename(target_path)
      
      register(target_path, tempfile.path)
      tempfiles << tempfile
      
      tempfile
    end
    
    # Generates a tempfile for the target path and registers it with self.
    # Returns the open tempfile.  Raises an error if the target_path is
    # already registered.
    def tempfile!(target_path)
      tempfile = Tempfile.new File.basename(target_path)
      
      register!(target_path, tempfile.path)
      tempfiles << tempfile
      
      tempfile
    end
    
    # Returns true if the source_path is for a tempfile generated by self.
    def tempfile?(source_path)
      tempfiles.any? {|tempfile| tempfile.path == source_path }
    end
    
    def recipe(target_path='recipe')
      target = tempfile(target_path)
      Recipe.new(target, self)
    end
    
    def build_file(file_name, target_path)
      register! target_path, file_path(file_name)
    end
    
    def build_template(template_name, target_path)
      source = template_path(template_name)
      
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
      path = registry[target_path]
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