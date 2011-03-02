require 'linecook/attributes'
require 'linecook/utils'
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
  #   recipe  = package.setup_recipe
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
  #   recipe = package.setup_recipe
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
    
    # Returns the current indentation string.
    attr_reader :current_indent
    
    def initialize(package, target_name)
      @package     = package
      @target_name = target_name
      @target      = package.setup_tempfile(target_name)
      @attributes  = {}
      @current_indent = ""
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
    
    # Loads the specified attributes file and merges the resulting attrs into
    # attrs. A block may be given to specify attrs as well; it will be
    # evaluated in the context of an Attributes instance.
    def attributes(attributes_name=nil, &block)
      attributes = @package.load_attributes(attributes_name)
      
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
      extend @package.load_helper(helper_name)
    end
    
    def next_target_name(target_name)
      @package.next_target_name(target_name)
    end
    
    def next_variable_name(context)
      @package.next_variable_name(context)
    end
    
    # The path to the named target, as it should be referenced in the final
    # script.  By default target_path simply returns target_name; this method
    # exists as a hook to rewrite target names to paths.
    def target_path(target_name=self.target_name)
      target_name
    end
    
    # Registers the specified file into package and returns the target_path to
    # the file.
    def file_path(file_name, target_name=file_name)
      @package.build_file(target_name, file_name)
      target_path target_name
    end
    
    # Looks up, builds, and registers the specified template and returns the
    # target_path to the resulting file.
    def template_path(template_name, target_name=template_name, locals={})
      locals[:attrs] ||= attrs
      
      @package.build_template(target_name, template_name, locals)
      target_path target_name
    end
    
    # Looks up, builds, and registers the specified recipe and returns the
    # target_path to the resulting file.
    def recipe_path(recipe_name, target_name=recipe_name)
      @package.build_recipe(target_name, recipe_name)
      target_path target_name
    end
    
    # Captures the output for a block, registers it, and returns the
    # target_path to the resulting file.
    def capture_path(target_name,  content=nil, &block)
      tempfile = @package.setup_tempfile(target_name)
      tempfile << content if content
      tempfile << capture(false) { instance_eval(&block) } if block
      tempfile.close
      
      target_path target_name
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
    
    # Indents the output of the block.  See current_indent.
    def indent(indent='  ', &block)
      @current_indent += indent
      concat capture(false, &block).gsub!(/^/, indent)
      @current_indent.chomp! indent
      self
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
