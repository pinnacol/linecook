require 'linecook/template'
require 'linecook/attributes'
require 'linecook/package'
require 'linecook/utils'

module Linecook
  class Recipe < Template
    class << self
      def build(env)
        package = Package.new(env)
        
        package.recipes.each do |recipe_name, target_name|
          new(target_name, env).evaluate(recipe_name)
        end
        
        package.close
        package
      end
    end
    
    alias target erbout
    
    attr_reader :target_name
    
    def initialize(target_name, env={})
      @target_name = target_name
      @package     = Package.init(env)
      @attributes  = Attributes.new(@package.env)
      @erbout      = @package.build(target_name)
    end
    
    def source_path(*relative_path)
      path = File.join(*relative_path)
      @package.manifest[path] or raise "no such file in manifest: #{path.inspect}"
    end
    
    def target_path(source_path)
      @package.build_path(source_path) ||
      @package.register(source_path, File.join("#{target_name}.d", File.basename(source_path)))
    end
    
    def target_file(name, content=nil)
      tempfile = @package.build File.join("#{target_name}.d", name)
      
      tempfile << content if content
      yield(tempfile) if block_given?
      
      target_path tempfile.path
    end
    
    def attrs
      @attributes.current
    end
    
    def attributes(attributes_name)
      path = source_path('attributes', "#{attributes_name}.rb")
      
      @attributes.instance_eval(File.read(path), path)
      @attributes.reset(false)
      self
    end
    
    def helpers(helper_name)
      require Utils.underscore(helper_name)
      extend Utils.constantize(helper_name)
    end
    
    def evaluate(recipe_name=target_name)
      path = source_path('recipes', "#{recipe_name}.rb")
      instance_eval(File.read(path), path)
      self
    end
    
    def file_path(file_name)
      path = source_path('files', file_name)
      target_path path
    end
    
    def capture_path(name, &block)
      content = capture(false) { instance_eval(&block) }
      target_file(name, content)
    end
    
    def recipe_path(recipe_name, target_name = recipe_name)
      source_path = 
        @package.built?(target_name) ?
        @package.source_path(target_name) :
        Recipe.new(target_name, @package).evaluate(recipe_name).target.path
      
      target_path source_path
    end
    
    def template_path(template_name, locals={})
      path = source_path('templates', "#{template_name}.erb")
      target_file template_name, Template.build(File.read(path), locals, path)
    end
    
    def close
      @package.close
      @package
    end
  end
end
