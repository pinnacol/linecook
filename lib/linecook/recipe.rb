require 'linecook/template'
require 'linecook/attributes'

module Linecook
  class Recipe < Template
    alias target erbout
    
    def initialize(target, package)
      @erbout      = target
      @package     = package
      @attributes  = Attributes.new(@package.env)
    end
    
    def target_name
      @package.target_path(target.path)
    end
    
    def target_path(source_path)
      @package.target_path(source_path) ||
      @package.register(File.join("#{target_name}.d", File.basename(source_path)), source_path)
    end
    
    def target_file(name, content=nil)
      tempfile = @package.tempfile File.join("#{target_name}.d", name)
      
      tempfile << content if content
      yield(tempfile) if block_given?
      
      tempfile.close
      target_path tempfile.path
    end
    
    def attrs
      @attributes.current
    end
    
    def attributes(attributes_name)
      path = @package.attributes_path(attributes_name)
      
      @attributes.instance_eval(File.read(path), path)
      @attributes.reset(false)
      self
    end
    
    def helpers(helper_name)
      require Utils.underscore(helper_name)
      extend Utils.constantize(helper_name)
    end
    
    def evaluate(recipe_name=target_name)
      path = @package.recipe_path(recipe_name)
      instance_eval(File.read(path), path)
      self
    end
    
    def file_path(file_name)
      target_path @package.file_path(file_name)
    end
    
    def capture_path(name, &block)
      content = capture(false) { instance_eval(&block) }
      target_file(name, content)
    end
    
    def recipe_path(recipe_name, target_name = recipe_name)
      source_path = 
        @package.registered_target?(target_name) ?
        @package.source_path(target_name) :
        @package.build_recipe(target_name) { evaluate(recipe_name) }.target.path
      
      target_path source_path
    end
    
    def template_path(template_name, locals={})
      path = @package.template_path(template_name)
      target_file template_name, Template.build(File.read(path), locals, path)
    end
  end
end
