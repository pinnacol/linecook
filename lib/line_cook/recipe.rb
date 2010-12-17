require 'line_cook/attributes'
require 'line_cook/templater'
require 'line_cook/cookbook'
require 'line_cook/utils'
require 'tempfile'

module LineCook
  class Recipe < Templater
    include Utils
    
    attr_reader :target_name
    attr_reader :cookbook
    attr_reader :registry
    attr_reader :current_count
    
    def initialize(target_name, options={})
      @target_name = target_name
      @target      = Tempfile.new(target_name)
      
      @cookbook    = options[:cookbook] || Cookbook.new
      @registry    = options[:registry] || {}
      @attributes  = Attributes.new(options[:attrs] || {})
      
      @registry[target.path] = target_name
      @cache         = [target]
      @target_count  = 0
      @current_count = 0
    end
    
    def source_path(type, *relative_path)
      relative_path = File.join(*relative_path)
      cookbook[type][relative_path]
    end
    
    def target_path(source_path)
      source_path = File.expand_path(source_path)
      
      registry[source_path] ||= begin
        basename = File.basename(source_path)
        
        # remove tempfile extension, if present
        if basename =~ /(.*?)[\.\d]+$/
          basename = $1
        end
        
        @target_count += 1
        File.join("#{target_name}.d", "#{@target_count - 1}-#{basename}")
      end
      
      registry[source_path]
    end
    
    def target_file(name, content=nil)
      tempfile = Tempfile.new(name)
      tempfile << content if content
      yield(tempfile) if block_given?
      
      tempfile.close
      @cache << tempfile
      target_path(tempfile.path)
    end
    
    def attrs
      @attributes.attrs
    end
    
    def attributes(name=nil, &block)
      attrs_path = name ? source_path(:attributes, "#{name.chomp('.rb')}.rb") : nil
      
      unless attrs_path || block
        raise "could not find attributes: #{"#{name.chomp('.rb')}.rb".inspect}"
      end
      
      @attributes.instance_eval(File.read(attrs_path), attrs_path) if attrs_path
      @attributes.instance_eval(&block) if block
      @attributes.reset(false)
      
      self
    end
    
    def helpers(name)
      const = Object
      constants = camelize(name).split(/::/)
      
      while const_name = constants.shift
        unless const.const_defined?(const_name)
          require underscore(name)
        end
        
        const = const.const_get(const_name)
      end
      
      extend const
    end
    
    def evaluate(name=nil, &block)
      recipe_path = name ? source_path(:recipes, "#{name.chomp(File.extname(name))}.rb") : nil
    
      unless recipe_path || block
        raise "could not find recipe: #{"#{name.chomp(File.extname(name))}.rb".inspect}"
      end
      
      instance_eval(File.read(recipe_path), recipe_path) if recipe_path
      instance_eval(&block) if block
      
      self
    end
    
    def file_path(name, &block)
      case
      when block
        target_file(name) do |tempfile|
          current = @target
          @target = tempfile

          begin
            instance_eval(&block) if block
          ensure
            @target = current
          end
        end
        
      when file_path = source_path(:files, name)
        target_path file_path
        
      else
        raise "could not find file: #{name.inspect}"
      end
    end
    
    def recipe_path(name, &block)
      target_path = nil
      
      registry.each_pair do |key, value|
        if value == name
          target_path = key
          break
        end
      end
      
      if target_path && block
        raise "block syntax cannot be used with existing recipe: #{name}"
      end
      
      target_path ||= begin
        recipe = Recipe.new(name, 
          :cookbook => cookbook,
          :registry => registry,
          :attrs    => @attributes.user_attrs
        )
        recipe.evaluate(name, &block)
        @cache << recipe
        recipe.target.path
      end
      
      target_path target_path
    end
    
    def template_path(name, locals={})
      unless template_path = source_path(:templates, "#{name}.erb")
        raise "could not find template: #{"#{name}.erb".inspect}"
      end
      
      template = File.read(template_path)
      target_file name, Templater.build(template, locals, template_path)
    end
    
    def close
      unless closed?
        @cache.each {|obj| obj.close }
        @registry.freeze
      end
      
      self
    end
    
    def closed?
      @target.closed?
    end
    
    def next_count
      @current_count += 1
    end
    
    def to_s
      target.flush
      target.rewind
      target.read
    end
  end
end
