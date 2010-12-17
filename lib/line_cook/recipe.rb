require 'line_cook/attributes'
require 'line_cook/templater'
require 'line_cook/cookbook'
require 'line_cook/utils'
require 'tempfile'

module LineCook
  class Recipe < Templater
    class << self
      def path_hash(dir='.')
        dir = File.expand_path(dir)
        
        Hash.new do |hash, relative_path|
          path = File.join(dir, relative_path.to_s)
          hash[relative_path] = File.exists?(path) ? path : nil
        end
      end
    end
    
    include Utils
    
    alias script target
    
    attr_reader :script_name
    
    # A hash of (relative_path, source_path) pairs defining files available
    # for use by the recipe.  See source_path.
    attr_reader :manifest
    
    # A hash of (source_path, relative_path) pairs defining files created by
    # the recipe.  See script_path.
    attr_reader :registry
    
    def initialize(options={})
      @script_name = options[:script_name] || 'script'
      @manifest    = options[:manifest] || self.class.path_hash
      @registry    = options[:registry] || {}
      
      @target      = Tempfile.new(script_name)
      @attributes  = Attributes.new(options[:attrs] || {})
      
      @registry[target.path] = script_name
      @cache = [target]
    end
    
    def source_path(*relative_path)
      manifest[File.join(*relative_path)]
    end
    
    def script_path(source_path)
      source_path = File.expand_path(source_path)
      
      registry[source_path] ||= begin
        dirname = "#{script_name}.d"
        basename = File.basename(source_path)

        # remove tempfile extension, if present
        if basename =~ /(.*?)[\.\d]+$/
          basename = $1
        end

        # generate a unique prefix for the basename
        count = 0
        registry.each_value do |path|
          if path.index(dirname) == 0
            count += 1
          end
        end

        File.join(dirname, "#{count}-#{basename}")
      end
      
      registry[source_path]
    end
    
    def script_file(name, content=nil)
      tempfile = Tempfile.new(name)
      tempfile << content if content
      yield(tempfile) if block_given?
      
      tempfile.close
      @cache << tempfile
      script_path(tempfile.path)
    end
    
    def attrs
      @attributes.attrs
    end
    
    def attributes(attributes_name)
      unless path = source_path('attributes', "#{attributes_name}.rb")
        raise "could not find attributes: #{attributes_name.inspect}"
      end
      
      @attributes.instance_eval(File.read(path), path)
      @attributes.reset(false)
      self
    end
    
    def helpers(helper_name)
      unless path = source_path('helpers', "#{helper_name}.rb")
        raise "could not find helper: #{helper_name.inspect}"
      end
      
      require path
      
      const = Object
      constants = camelize(helper_name).split(/::/)
      
      while const_name = constants.shift
        const = const.const_get(const_name)
      end
      
      extend const
    end
    
    def evaluate(recipe_name=nil)
      unless path = source_path('recipes', "#{recipe_name}.rb")
        raise "could not find recipe: #{recipe_name.inspect}"
      end
      
      instance_eval(File.read(path), path)
      self
    end
    
    def file_path(file_name)
      unless path = source_path('files', file_name)
        raise "could not find file: #{file_name.inspect}"
      end
      
      script_path path
    end
    
    def capture_path(name, &block)
      content = capture { instance_eval(&block) }
      script_file(name, content)
    end
    
    def recipe_path(recipe_name)
      registry.each_pair do |key, value|
        if value == recipe_name
          return script_path(key)
        end
      end
      
      recipe = Recipe.new(
        :script_name => recipe_name, 
        :manifest => manifest,
        :registry => registry,
        :attrs    => @attributes.user_attrs
      )
      recipe.evaluate(recipe_name)
      @cache << recipe
      
      script_path recipe.script.path
    end
    
    def template_path(name, locals={})
      unless path = source_path('templates', "#{name}.erb")
        raise "could not find template: #{name.inspect}"
      end
      
      script_file name, Templater.build(File.read(path), locals, path)
    end
    
    def close
      unless closed?
        @cache.each {|obj| obj.close }
        @registry.freeze
      end
      
      self
    end
  end
end
