require 'linecook/attributes'
require 'erb'

module Linecook
  # Recipe is the context in which recipes are evaluated (literally).  Recipe
  # uses a little ERB trick to allow compiled ERB snippets to build text using
  # method calls. For example:
  #
  #   module Helper
  #     # This is compiled ERB code, prefixed by 'self.', ie:
  #     #
  #     #   "self." + ERB.new("echo '<%= args.join(' ') %>'\n").src
  #     #
  #     def echo(*args)
  #       self._erbout = ''; _erbout.concat "echo '"; _erbout.concat(( args.join(' ') ).to_s); _erbout.concat "'\n"
  #       _erbout
  #     end
  #   end
  #
  #   package = Package.new
  #   recipe  = package.recipe
  #
  #   recipe.extend Helper
  #   recipe.instance_eval do
  #     echo 'a', 'b c'
  #     echo 'X Y'.downcase, :z
  #   end
  #
  #   "\n" + recipe.result
  #   # => %{
  #   # echo 'a b c'
  #   # echo 'x y z'
  #   # }
  #
  # Recipes control the _erbout context, such that reformatting is possible
  # before any content is emitted. This allows such things as indentation.
  #
  #   recipe = package.recipe
  #   recipe.extend Helper
  #   recipe.instance_eval do
  #     echo 'outer'
  #     indent do
  #       echo 'inner'
  #     end
  #     echo 'outer'
  #   end
  #
  #   "\n" + template.result
  #   # => %{
  #   # echo 'outer'
  #   #   echo 'inner'
  #   # echo 'outer'
  #   # }
  #
  # See _erbout and _erbout= for the ERB trick that makes this all possible.
  class Recipe
    
    # The recipe target (an IO)
    attr_reader :target
    
    # The name of target in package
    attr_reader :target_name
    
    def initialize(package, target_name)
      @package     = package
      @target_name = target_name
      @target      = @package.tempfile(target_name)
      @attributes  = {}
    end
    
    # Returns self.  In the context of a compiled ERB helper, this method
    # directs output to Recipe#concat and thereby into target.  This trick is
    # what allows Recipe to capture and reformat output.
    def _erbout
      self
    end
    
    # Does nothing except allow ERB helpers to be written in the form:
    #
    #   def helper_method
    #     eval("self." + ERB.new('template').src)
    #   end
    # 
    # For clarity this is the equivalent code:
    #
    #   def helper_method
    #     self._erbout = ''; _erbout.concat "template"; _erbout
    #   end
    #
    # Compiled ERB source always begins with "_erbout = ''" to set the
    # intended ERB target.  By prepending "self." to the source code, the
    # initial assignment gets thrown out by this method. Thereafter _erbout
    # resolves to Recipe#_erbout, and thus Recipe gains control of the
    # output.
    def _erbout=(input)
    end
    
    # Pushes input to the target using '<<'.  Returns self.
    def concat(input)
      target << input
      self
    end
    
    # Closes target and returns self.
    def close
      target.close unless closed?
      self
    end
    
    # Returns true if target is closed.
    def closed?
      target.closed?
    end
    
    # Returns the current contents of target.
    def result
      if closed?
        @package.content(target_name)
      else
        target.flush
        target.rewind
        target.read
      end
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
      target_name = File.join(target_dir_name, name)
      tempfile = @package.tempfile target_name
      
      tempfile << content if content
      yield(tempfile) if block_given?
      
      tempfile.close
      target_path target_name
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
      
      binding = OpenStruct.new(locals).send(:binding)
      content = @package.template(template_name).result(binding)
      
      target_file template_name, content
    end
    
    # Looks up, builds, and registers the specified recipe and returns the
    # target_path to the resulting file.
    def recipe_path(recipe_name, target_name = recipe_name)
      unless @package.registry.has_key?(target_name)
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
    
    # Captures and returns output for the duration of a block.  The output is
    # stripped if strip is true.
    def capture(strip=true)
      current, redirect = target, StringIO.new
      
      begin
        @target = redirect
        yield
      ensure
        @target = current
      end
      
      str = redirect.string
      str.strip! if strip
      str
    end
    
    # Indents the output of the block.
    def indent(indent='  ', &block)
      capture(&block).split("\n").each do |line|
        concat "#{indent}#{line}\n"
      end
      self
    end
    
    # Indents the output of the block within each of the nestings.  Nestings
    # are [start_line, end_line] pairs which are used to wrap the output.
    def nest(*nestings)
      options  = nestings.last.kind_of?(Hash) ? nestings.pop : {}
      indent   = options[:indent] || "  "
      line_sep = options[:line_sep] || "\n"
      
      content = capture { yield }
      return content if nestings.empty?
      
      depth = nestings.length
      lines = [indent * depth + content.gsub(/#{line_sep}/, line_sep + indent * depth)]

      nestings.reverse_each do |(start_line, end_line)|
        depth -= 1
        lines.unshift(indent * depth + start_line)
        lines << (indent * depth + end_line)
      end

      concat lines.join(line_sep)
    end
    
    # Strips whitespace from the end of target. To do so the target is rewound
    # in chunks of n chars and then re-written without whitespace.
    #
    # Yields to a block if given, before performing the rstrip.
    def rstrip(n=10)
      yield if block_given?
      
      pos = target.pos
      n = pos if pos < n
      start = pos - n
      
      target.pos = start
      tail = target.read(n).rstrip
      
      target.pos = start
      target.truncate start
      
      tail.length == 0 && start > 0 ? rstrip(n) : concat(tail)
    end
  end
end
