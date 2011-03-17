require 'linecook/attributes'
require 'linecook/proxy'
require 'linecook/utils'
require 'erb'
require 'stringio'

module Linecook
  # Recipe is the context in which recipes are evaluated (literally).  Recipe
  # uses compiled ERB snippets to build text using method calls. For example:
  #
  #   module Helper
  #     # This is an ERB template compiled to write to a Recipe.
  #     #
  #     #   compiler = ERB::Compiler.new('<>')
  #     #   compiler.put_cmd = "write"
  #     #   compiler.insert_cmd = "write"
  #     #   compiler.compile("echo '<%= args.join(' ') %>'\n")
  #     #
  #     def echo(*args)
  #       write "echo '"; write(( args.join(' ') ).to_s); write "'\n"
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
  class Recipe
    
    # The recipe package
    attr_reader :_package_
    
    # The recipe target
    attr_reader :_target_
    
    # The target name of self in package
    attr_reader :_target_name_
    
    # The recipe proxy
    attr_reader :_proxy_
    
    # The current target for self set as needed during captures; equal to
    # _target_ otherwise.
    attr_reader :target
    
    # The current target_name for self set as needed during captures; equal to
    # _target_name_ otherwise.
    attr_reader :target_name
    
    def initialize(package, target_name, mode)
      @_package_     = package
      @_target_name_ = target_name
      @_target_      = package.setup_tempfile(target_name, mode)
      @_proxy_       = Proxy.new(self)
      
      @target_name   = @_target_name_
      @target        = @_target_
      
      @chain       = false
      @attributes  = {}
      @indents     = []
      @outdents    = []
    end
    
    # Closes _target_ and returns self.
    def close
      unless closed?
        _target_.close
      end
      self
    end
    
    # Returns true if _target_ is closed.
    def closed?
      _target_.closed?
    end
    
    # Returns the current contents of target, or the contents of _target_ if
    # closed? is true.
    def result
      if closed?
        _package_.content(_target_name_)
      else
        target.flush
        target.rewind
        target.read
      end
    end
    
    # Loads the specified attributes file and merges the results into attrs. A
    # block may be given to specify attrs as well; it will be evaluated in the
    # context of an Attributes instance.
    def attributes(attributes_name=nil, &block)
      attributes = _package_.load_attributes(attributes_name)
      
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
      @attrs ||= Utils.deep_merge(@attributes, _package_.env)
    end
    
    # Looks up and extends self with the specified helper.
    def helpers(helper_name)
      extend _package_.load_helper(helper_name)
    end
    
    # Returns an expression that evaluates to the package dir, assuming that
    # $0 evaluates to the full path to the current recipe.
    def package_dir
      "${0%/#{target_name}}"
    end
    
    # The path to the named target as it should be referenced in the final
    # script, specifically target_name joined to package_dir.
    def target_path(target_name)
      File.join(package_dir, target_name)
    end
    
    # Registers the specified file into package and returns the target_path to
    # the file.
    def file_path(file_name, target_name=file_name, mode=0600)
      _package_.build_file(target_name, file_name, mode)
      target_path target_name
    end
    
    # Looks up, builds, and registers the specified template and returns the
    # target_path to the resulting file.
    def template_path(template_name, target_name=template_name, mode=0600, locals={})
      locals[:attrs] ||= attrs
      
      _package_.build_template(target_name, template_name, mode, locals)
      target_path target_name
    end
    
    # Looks up, builds, and registers the specified recipe and returns the
    # target_path to the resulting file.
    def recipe_path(recipe_name, target_name=recipe_name, mode=0700)
      _package_.build_recipe(target_name, recipe_name, mode)
      target_path target_name
    end
    
    # Captures the output for a block, registers it, and returns the
    # target_path to the resulting file.  The current target and target_name
    # are updated for the duration of the block.
    def capture_path(target_name, mode=0600)
      tempfile = _package_.setup_tempfile(target_name, mode)
      capture_block(tempfile) do
        current = @target_name
        
        begin
          @target_name = target_name
          yield
        ensure
          @target_name = current
        end
        
      end
      tempfile.close
      
      target_path target_name
    end
    
    # Captures output to the target for the duration of a block.  Returns the
    # capture target.
    def capture_block(target=StringIO.new)
      current = @target

      begin
        @target = target
        yield
      ensure
        @target = current
      end

      target
    end
    
    # Captures and returns output for the duration of a block by redirecting
    # target to a temporary buffer.
    def capture_str(&block)
      capture_block(&block).string
    end
    
    # Writes input to target using 'write'.  Returns self.
    def write(input)
      target.write input
      self
    end
    
    # Writes input to target using 'puts'.  Returns self.
    def writeln(input)
      target.puts input
      self
    end
    
    # Truncates the contents of target starting at the first match of pattern
    # and returns the resulting match data. If a block is given then rewrite
    # yields the match data to the block and returns the block result.
    # 
    # ==== Notes
    #
    # Rewrites can be computationally expensive because they require the
    # current target to be flushed, rewound, and read in it's entirety.  In
    # practice the performance of rewrite is almost never an issue because
    # recipe output is usually small in size.
    #
    # If performance becomes an issue, then wrap the rewritten bits in a
    # capture block to reassign the current target to a StringIO (which is
    # much faster to rewrite), and to limit the scope of the rewritten text.
    def rewrite(pattern)
      if match = pattern.match(result)
        start = match.begin(0)
        target.pos = start
        target.truncate start
      end
      
      block_given? ? yield(match) : match
    end
    
    # Strips whitespace from the end of target and returns the stripped
    # whitespace, or an empty string if no whitespace is available.
    def rstrip
      match = rewrite(/\s+\z/)
      match ? match[0] : ''
    end
    
    # Indents the output of the block.  Indents may be nested. To prevent a
    # section from being indented, enclose it within outdent which resets
    # indentation to nothing for the duration of a block.
    #
    # Example:
    #
    #   writeln 'a'
    #   indent do
    #     writeln 'b'
    #     outdent do
    #       writeln 'c'
    #       indent do
    #         writeln 'd'
    #       end
    #       writeln 'c'
    #     end
    #     writeln 'b'
    #   end
    #   writeln 'a'
    #
    #   "\n" + result
    #   # => %q{
    #   # a
    #   #   b
    #   # c
    #   #   d
    #   # c
    #   #   b
    #   # a
    #   # }
    #
    def indent(indent='  ', &block)
      @indents << @indents.last.to_s + indent
      str = capture_block(&block).string
      @indents.pop

      unless str.empty?
        str.gsub!(/^/, indent)

        if @indents.empty?
          @outdents.each do |flag|
            str.gsub!(/#{flag}(\d+):(.*?)#{flag}/m) do
              $2.gsub!(/^.{#{$1.to_i}}/, '')
            end
          end
          @outdents.clear
        end

        writeln str
      end

      self
    end

    # Resets indentation to nothing for a section of text indented by indent.
    #
    # === Notes
    #
    # Outdent works by setting a text flag around the outdented section; the
    # flag and indentation is later stripped out using regexps.  For that
    # reason, be sure flag is not something that will appear anywhere else in
    # the section.
    #
    # The default flag is like ':outdent_N:' where N is a big random number.
    def outdent(flag=nil)
      current_indent = @indents.last
      
      if current_indent.nil?
        yield
      else
        flag ||= ":outdent_#{rand(10000000)}:"
        @outdents << flag
        
        write "#{flag}#{current_indent.length}:#{rstrip}"
        @indents << ''
        
        yield
        
        @indents.pop
        
        write "#{flag}#{rstrip}"
      end
      
      self
    end
    
    # Sets chain? to true and calls the method (thereby allowing the method to
    # invoke chain-specific behavior).  Chain is invoked via the chain_proxy
    # which is returned by helper methods.
    def chain(method_name, *args, &block)
      @chain = true
      send(method_name, *args, &block)
    end
    
    # Returns true if the current context was invoked through chain.
    def chain?
      @chain
    end
    
    # Sets chain to false and returns the proxy.
    def chain_proxy
      @chain = false
      _proxy_
    end
    
    # Captures a block of output and concats to the named callback.
    def callback(name, &block)
      target = _package_.callbacks[name]
      capture_block(target, &block)
    end
    
    # Writes the specified callback to the current target.
    def write_callback(name)
      write _package_.callbacks[name].string
    end
  end
end
