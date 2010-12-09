require 'line_cook/attributes'
require 'tap/env/constant'
require 'tap/templater'
require 'tempfile'
require 'stringio'

require 'line_cook/patches/templater'

module LineCook
  class Recipe
    
    attr_reader :target_name
    attr_reader :target
    attr_reader :sources
    attr_reader :registry
    attr_reader :current_count
    
    def initialize(target_name, options={})
      @target_name = target_name
      @target      = Tempfile.new(target_name)
      
      @sources     = options[:sources] || [Dir.pwd]
      @registry    = options[:registry] || {}
      @attributes  = Attributes.new(options[:attrs] || {})
      
      @registry[target.path] = target_name
      @cache         = [target]
      @target_count  = 0
      @current_count = 0
    end
    
    def source_path(*relative_path)
      relative_path = File.join(*relative_path)
      
      sources.each do |source|
        full_path = File.expand_path(relative_path, source)
        return full_path if File.exists?(full_path)
      end
      
      nil
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
      attrs_path = name ? source_path('attributes', "#{name.chomp('.rb')}.rb") : nil
      
      unless attrs_path || block
        raise "could not find attributes: #{"#{name.chomp('.rb')}.rb".inspect}"
      end
      
      @attributes.instance_eval(File.read(attrs_path), attrs_path) if attrs_path
      @attributes.instance_eval(&block) if block
      @attributes.reset(false)
      
      self
    end
    
    def shell(shell_name, *args)
      helpers File.join("line_cook/helpers", shell_name)
      shebang(*args)
      nil
    end
    
    def helpers(name)
      const = Tap::Env::Constant.new(name.camelize, name.underscore)
      extend const.constantize
    end
    
    def evaluate(name=nil, &block)
      recipe_path = name ? source_path('recipes', "#{name.chomp(File.extname(name))}.rb") : nil
    
      unless recipe_path || block
        raise "could not find recipe: #{"#{name.chomp(File.extname(name))}.rb".inspect}"
      end
      
      instance_eval(File.read(recipe_path), recipe_path) if recipe_path
      instance_eval(&block) if block
      
      self
    end
    
    def file_path(name)
      unless file_path = source_path('files', name)
        raise "could not find file: #{name.inspect}"
      end
      
      target_path file_path
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
          :sources  => sources,
          :registry => registry,
          :attrs    => @attributes.user_attrs
        )
        recipe.evaluate(name, &block)
        @cache << recipe
        recipe.target.path
      end
      
      target_path target_path
    end
    
    def script_path(name, &block)
      script_path = source_path('scripts', name)
      
      unless script_path || block
        raise "could not find script: #{name.inspect}"
      end
      
      content = script_path ? File.read(script_path) : nil
      
      target_file(name, content) do |tempfile|
        current = @target
        @target = tempfile

        begin
          instance_eval(&block) if block
        ensure
          @target = current
        end
      end
    end
    
    def template_path(name, locals={})
      unless template_path = source_path('templates', "#{name}.erb")
        raise "could not find template: #{"#{name}.erb".inspect}"
      end
      
      template = File.read(template_path)
      target_file name, Tap::Templater.build(template, locals, template_path)
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
    
    # Returns self (not the underlying erbout storage that actually receives
    # the output lines).  In the ERB context, this method directs erb outputs
    # to Templater#concat and into the redirect mechanism.
    def _erbout
      self
    end
    
    # Sets the underlying erbout storage to input.
    def _erbout=(input)
    end
    
    # Concatenates the specified input to the underlying erbout storage.
    def concat(input)
      target << input
      self
    end
    
    def capture
      current, redirect = @target, StringIO.new
      
      begin
        @target = redirect
        yield
      ensure
        @target = current
      end
      
      redirect.string.strip!
    end
    
    def indent(indent='  ', &block)
      capture(&block).split("\n").each do |line|
        concat "#{indent}#{line}\n"
      end
      self
    end
    
    def rstrip(n=10)
      yield if block_given?
      
      pos = target.pos
      n = pos if pos < n
      start = pos - n
      
      target.pos = start
      tail = target.read(n).rstrip
      
      target.pos = start
      target.truncate start
      
      tail.length == 0 && start > 0 ? rstrip(n * 2) : concat(tail)
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
