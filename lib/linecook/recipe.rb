require 'linecook/template'
require 'linecook/attributes'

module Linecook
  class Recipe < Template
    attr_reader :target_name
    attr_reader :target_dir_name
    
    def initialize(target, package)
      @target      = target
      @attributes  = {}
      @package     = package
      @target_name = @package.target_path(target.path)
      @target_dir_name = "#{target_name}.d"
    end
    
    def target_path(target_path=target_name)
      target_path
    end
    
    def target_file(name, content=nil)
      tempfile = @package.tempfile File.join(target_dir_name, name)
      
      tempfile << content if content
      yield(tempfile) if block_given?
      
      tempfile.close
      target_path @package.target_path(tempfile.path)
    end
    
    def attrs
      @attrs ||= Utils.deep_merge(@attributes, @package.env)
    end
    
    def attributes(attributes_name)
      path = @package.attributes_path(attributes_name)
      
      attributes  = Attributes.new
      attributes.instance_eval(File.read(path), path)
      
      @attributes = Utils.deep_merge(@attributes, attributes.to_hash)
      @attrs = nil
      
      @attributes
    end
    
    def helpers(helper_name)
      extend @package.helper(helper_name)
    end
    
    def variable(name)
      @package.variable(name)
    end
    
    def evaluate(recipe_name=target_name)
      path = @package.recipe_path(recipe_name)
      instance_eval(File.read(path), path)
      self
    end
    
    def file_path(file_name)
      file_path = @package.file_path(file_name)
      target_path @package.register(File.join(target_dir_name, file_name), file_path)
    end
    
    def template_path(template_name, locals={})
      locals[:attrs] ||= attrs
      target_file template_name, @package.template(template_name, locals)
    end
    
    def recipe_path(recipe_name, target_name = recipe_name)
      unless @package.registered_target?(target_name)
        @package.build_recipe(recipe_name, target_name)
      end
      
      target_path target_name
    end
    
    def capture_path(name, &block)
      content = capture(false) { instance_eval(&block) }
      target_file(name, content)
    end
  end
end
