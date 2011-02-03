require 'linecook/template'
require 'linecook/attributes'

module Linecook
  # Recipe is the context in which recipes are evaluated (literally).  Recipes
  # use helper methods to write text to a target file.   Recipes always live
  # in the context of a Package.  The package provides support for looking up
  # source files for attributes, helpers, etc. and for creating files
  # associated with the target.
  class Recipe < Template
    
    # The name of target in package
    attr_reader :target_name
    
    def initialize(target, package)
      @target      = target
      @attributes  = {}
      @package     = package
      @target_name = @package.target_name(target.path)
    end
    
    # The name of directory in package where associated files are added
    def target_dir_name
      @target_dir_name ||= "#{target_name}.d"
    end
    
    # The path to the named target, as it should be referenced in the final
    # script.  By default target_path simply returns target_name; this method
    # exists as a hook to rewrite target names to paths.
    def target_path(target_name=self.target_name)
      target_name
    end
    
    # Generates and returns the target_path to the named file.  Content for
    # the file can be specified as the content arg and/or with a block which
    # recieves an IO representing the new file.
    def target_file(name, content=nil) # :yields: io
      tempfile = @package.tempfile File.join(target_dir_name, name)
      
      tempfile << content if content
      yield(tempfile) if block_given?
      
      tempfile.close
      target_path @package.target_name(tempfile.path)
    end
    
    # Loads the specified attributes file and merges the resulting attrs into
    # attrs. A block may be given to specify attrs as well; it will be
    # evaluated in the context of an Attributes instance.
    def attributes(attributes_name=nil, &block)
      attributes  = Attributes.new
      
      if attributes_name
        path = @package.attributes_path(attributes_name)
        attributes.instance_eval(File.read(path), path)
      end
      
      if block_given?
        attributes.instance_eval(&block)
      end
      
      @attributes = Utils.deep_merge(@attributes, attributes.to_hash)
      @attrs = nil
      self
    end
    
    # Returns the package env merged over any attrs specified by attributes.
    # The attrs hash should be treated as if it were read-only because changes
    # could alter the package env and thereby spill over into other recipes.
    def attrs
      @attrs ||= Utils.deep_merge(@attributes, @package.env)
    end
    
    # Looks up and extends self with the specified helper.
    def helpers(helper_name)
      extend @package.helper(helper_name)
    end
    
    def variable(name)
      @package.variable(name)
    end
    
    # Looks up and evaluates the specified recipe in the context of self.
    # Returns self.
    def evaluate(recipe_name=target_name)
      path = @package.recipe_path(recipe_name)
      instance_eval(File.read(path), path)
      self
    end
    
    # Registers the specified file into package and returns the target_path to
    # the file.
    def file_path(file_name)
      file_path = @package.file_path(file_name)
      target_path @package.register(File.join(target_dir_name, file_name), file_path)
    end
    
    # Looks up, builds, and registers the specified template and returns the
    # target_path to the resulting file.
    def template_path(template_name, locals={})
      locals[:attrs] ||= attrs
      target_file template_name, @package.template(template_name, locals)
    end
    
    # Looks up, builds, and registers the specified recipe and returns the
    # target_path to the resulting file.
    def recipe_path(recipe_name, target_name = recipe_name)
      unless @package.registered_target?(target_name)
        @package.build_recipe(recipe_name, target_name)
      end
      
      target_path target_name
    end
    
    # Captures the output for a block, registers it, and returns the
    # target_path to the resulting file.
    def capture_path(name, &block)
      content = capture(false) { instance_eval(&block) }
      target_file(name, content)
    end
  end
end
