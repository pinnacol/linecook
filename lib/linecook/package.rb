require 'linecook/recipe'
require 'linecook/template'
require 'tempfile'

module Linecook
  class Package
    class << self
      def init(env={}, cookbook=nil)
        package = new(env)
        
        if cookbook
          if cookbook_config = package.cookbook_config
            cookbook = cookbook.merge(cookbook_config)
          end
          
          package.config[MANIFEST_KEY] ||= cookbook.manifest
        end
        
        package
      end
      
      def load(path=nil, cookbook=nil)
        env = Utils.load_config(path)
        init(env, cookbook)
      end
      
      def setup(env={}, cookbook=nil)
        env.kind_of?(String) ? load(env, cookbook) : init(env, cookbook)
      end
      
      def build(path=nil, cookbook=nil)
        package = load(path, cookbook)
        package.build
        package.close
        package
      end
    end
    
    CONFIG_KEY          = 'linecook'
    COOKBOOK_CONFIG_KEY = 'cookbook'
    MANIFEST_KEY        = 'manifest'
    REGISTRY_KEY        = 'registry'
    FILES_KEY           = 'files'
    TEMPLATES_KEY       = 'templates'
    RECIPES_KEY         = 'recipes'
    
    # The package environment
    attr_reader :env
    
    # An array of tempfiles generated by self (used to cleanup on close)
    attr_reader :tempfiles
    
    # A hash of counters used by variable.
    attr_reader :counters
    
    def initialize(env={})
      @env = env
      @tempfiles = []
      @counters = Hash.new(0)
    end
    
    # Returns the linecook configs in env, as keyed by CONFIG_KEY.  Defaults
    # to an empty hash.
    def config
      env[CONFIG_KEY] ||= {}
    end
    
    # Returns the cookbook configs in config, as keyed by COOKBOOK_CONFIG_KEY.
    # Defaults to an empty hash.
    def cookbook_config
      config[COOKBOOK_CONFIG_KEY]
    end
    
    # Returns the manifest in config, as keyed by MANIFEST_KEY. Defaults to an
    # empty hash.
    def manifest
      config[MANIFEST_KEY] ||= Hash.new {|hash, key| hash[key] = {} }
    end
    
    # Returns the hash of (source, target) pairs identifying which of the
    # files will be built into self by build.  Files are identified by
    # FILES_KEY in config, and normalized the same way as recipes.
    def files
      normalize(FILES_KEY)
    end
    
    # Returns the hash of (source, target) pairs identifying which templates
    # will be built into self by build. Templates are identified by
    # TEMPLATES_KEY in config, and normalized the same way as recipes.
    def templates
      normalize(TEMPLATES_KEY)
    end
    
    # Returns the hash of (source, target) pairs identifying which recipes
    # will be built into self by build.  Recipes are identified by RECIPES_KEY
    # in config.
    #
    # Non-hash recipes are normalized by expanding arrays into a redundant
    # hash, such that each entry has the same source and target (more
    # concretely, the 'example' recipe is registered as the 'example' script).
    # Strings are split along colons into an array and then expanded.
    #
    # For example:
    #
    #   package = Package.new('linecook' => {'recipes' => 'a:b:c'})
    #   package.recipes   # => {'a' => 'a', 'b' => 'b', 'c' => 'c'}
    #
    def recipes
      normalize(RECIPES_KEY)
    end
    
    # Returns the registry in config, as keyed by REGISTRY_KEY. Defaults to an
    # empty hash.  A hash of (target_name, source_path) pairs identifying
    # files that should be included in a package
    def registry
      config[REGISTRY_KEY] ||= {}
    end
    
    # Registers the source_path to target_name in the registry and
    # revese_registry.  Raises an error if the source_path is already
    # registered.
    def register(target_name, source_path)
      source_path = File.expand_path(source_path)
      
      if registry.has_key?(target_name) && registry[target_name] != source_path
        raise "already registered: #{target_name.inspect}"
      end
      
      registry[target_name] = source_path
      target_name
    end
    
    # Increments target_name until an unregistered name is found and returns
    # the result.
    def next_target_name(target_name='file')
      count = 0
      registry.each_key do |key|
        if key.index(target_name) == 0
          count += 1
        end
      end
      
      if count > 0
        target_name = "#{target_name}.#{count}"
      end
      
      target_name
    end
    
    # Returns a package-unique variable with base 'name'.
    def next_variable_name(context)
      context = context.to_s
      
      count = counters[context]
      counters[context] += 1
      
      "#{context}#{count}"
    end
    
    # Returns true if there is a path for the specified resource in manifest.
    def resource?(type, path)
      resources = manifest[type]
      resources && resources.has_key?(path)
    end
    
    # Returns the path to the resource in manfiest.  Raises an error if there
    # is no such resource.
    def resource_path(type, path)
      resources = manifest[type] || {}
      resources[path] or raise "no such resource in manifest: #{type.inspect} #{path.inspect}"
    end
    
    # Returns the resource_path the named attributes file (ex 'attributes/name.rb').
    def attributes_path(attributes_name)
      resource_path('attributes', attributes_name)
    end
    
    # Returns the resource_path the named file (ex 'files/name')
    def file_path(file_name)
      resource_path('files', file_name)
    end
    
    # Returns the resource_path the named template file (ex 'templates/name.erb').
    def template_path(template_name)
      resource_path('templates', template_name)
    end
    
    # Returns the resource_path the named recipe file (ex 'recipes/name.rb').
    def recipe_path(recipe_name)
      resource_path('recipes', recipe_name)
    end
    
    def load_attributes(attributes_name=nil)
      attributes = Attributes.new
      
      if attributes_name
        path = attributes_path(attributes_name)
        attributes.instance_eval(File.read(path), path)
      end
      
      attributes
    end
    
    def load_template(template_name)
      Template.new template_path(template_name)
    end
    
    def load_helper(helper_name)
      require Utils.underscore(helper_name)
      Utils.constantize(helper_name)
    end
    
    # Returns a recipe bound to self.
    def setup_recipe(target_name = next_target_name)
      Recipe.new(self, target_name)
    end
    
    # Generates a tempfile for the target path and registers it with self. As
    # with register, the target_name will be incremented as needed.  Returns
    # the open tempfile.
    def setup_tempfile(target_name = next_target_name)
      tempfile = Tempfile.new File.basename(target_name)
      
      register(target_name, tempfile.path)
      tempfiles << tempfile
      
      tempfile
    end
    
    # Returns true if the source_path is for a tempfile generated by self.
    def tempfile?(source_path)
      tempfiles.any? {|tempfile| tempfile.path == source_path }
    end
    
    # Looks up the file with the specified name using file_path and registers
    # it to target_name.  Raises an error if the target is already registered.
    def build_file(target_name, file_name)
      register target_name, file_path(file_name)
      self
    end
    
    # Looks up the template with the specified name using template_path,
    # builds, and registers it to target_name.  The locals will be set for
    # access in the template context.  Raises an error if the target is
    # already registered. Returns self.
    def build_template(target_name, template_name, locals=env)
      content = load_template(template_name).build(locals)
      
      target = setup_tempfile(target_name)
      target << content
      target.close
      self
    end
    
    # Looks up the recipe with the specified name using recipe_path, evaluates
    # it, and registers the result to target_name.  Raises an error if the
    # target is already registered. Returns self.
    def build_recipe(target_name, recipe_name)
      path = recipe_path(recipe_name)
      recipe = setup_recipe(target_name)
      recipe.instance_eval(File.read(path), path)
      recipe.close
      
      self
    end
    
    # Builds the files, templates, and recipes for self.  Returns self.
    def build
      files.each do |target_name, file_name|
        build_file(target_name, file_name)
      end
      
      templates.each do |target_name, template_name|
        build_template(target_name, template_name)
      end
      
      recipes.each do |target_name, recipe_name|
        build_recipe(target_name, recipe_name)
      end
      
      self
    end
    
    # Returns the content of the source_path for target_name, as registered in
    # self.  Returns nil if the target is not registered.
    def content(target_name, length=nil, offset=nil)
      path = registry[target_name]
      path ? File.read(path, length, offset) : nil
    end
    
    # Closes all tempfiles and returns self.
    def close
      tempfiles.each do |tempfile|
        tempfile.close unless tempfile.closed?
      end
      self
    end
    
    def reset
      close
      tempfiles.clear
      registry.clear
      counters.clear
      self
    end
    
    # Closes self and exports the registry to dir by copying or moving the
    # registered source paths to the target path under dir.  By default
    # tempfiles are moved while all other files are copied.
    #
    # Returns registry, which is re-written to reflect the new source paths.
    def export(dir, options={})
      close
      
      options = {
        :allow_move => true
      }.merge(options)
      
      allow_move = options[:allow_move]
      
      registry.each_key do |target_name|
        export_path = File.join(dir, target_name)
        export_dir  = File.dirname(export_path)
        
        unless File.exists?(export_dir)
          FileUtils.mkdir_p(export_dir)
        end
        
        source_path = registry[target_name]
        
        if allow_move && tempfile?(source_path)
          FileUtils.mv(source_path, export_path)
        else
          FileUtils.cp(source_path, export_path)
        end
        
        registry[target_name] = export_path
      end
      
      tempfiles.clear
      registry
    end
    
    private
    
    def normalize(type) # :nodoc:
      obj = config[type]
      config[type] = Utils.hashify(obj) or raise "invalid #{type}: #{obj.inspect}"
    end
  end
end