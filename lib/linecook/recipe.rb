require 'linecook/template'
require 'linecook/script'
require 'linecook/utils'

module Linecook
  class Recipe < Template
    include Utils
    
    alias target erbout
    
    attr_reader :target_name
    
    attr_reader :script
    
    def initialize(target_name, script)
      @target_name = target_name
      @script      = script
      @attributes  = script.attributes
      @erbout      = script.tempfile(target_name)
    end
    
    def source_path(*relative_path)
      script.source_path(*relative_path)
    end
    
    def target_path(source_path)
      source_path = File.expand_path(source_path)
      
      script.registry[source_path] || 
      script.register(source_path, File.join("#{target_name}.d", File.basename(source_path)))
    end
    
    def target_file(name, content=nil)
      tempfile = script.tempfile(File.join("#{target_name}.d", name), name)
      
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
      require underscore(helper_name)
      
      const = Object
      constants = camelize(helper_name).split(/::/)
      while name = constants.shift
        const = const.const_get(name)
      end
      
      extend const
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
    
    def recipe_path(recipe_name)
      script.registry.each_pair do |source, target|
        if target == recipe_name
          return target_path(source)
        end
      end
      
      recipe = Recipe.new(recipe_name, script)
      recipe.evaluate
      recipe.close
      
      script.cache << recipe
      target_path recipe.target.path
    end
    
    def template_path(template_name, locals={})
      path = source_path('templates', "#{template_name}.erb")
      target_file template_name, Template.build(File.read(path), locals, path)
    end
  end
end
