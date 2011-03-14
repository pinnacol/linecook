require 'linecook/attributes'
require 'linecook/proxy'
require 'linecook/utils'
require 'erb'

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
  # ==== Method Name Conventions
  #
  # Recipe uses underscores to hint at the use case for methods, and to free
  # up the non-underscore method names for use by the dsl and helpers.  In
  # general:
  #
  #   method_name     dsl methods or helpers that write content to the target
  #   _method_name    returns helper output without writing to target
  #   _method_name_   internal methods used within helpers
  #
  # These conventions do not imply public/private status with respect to the
  # API; for example _target_ is a permanent, public method in the API.
  # Wrapping it in underscores implies functionality, or who is likely to use
  # it (writers of helpers, writers of recipes, etc).
   class Recipe
    
    # The recipe package
    attr_reader :_package_
    
    # The recipe target
    attr_reader :_target_
    
    # The name of target in package
    attr_reader :_target_name_
    
    # The recipe proxy
    attr_reader :_proxy_
    
    def initialize(package, target_name, mode)
      @_package_     = package
      @_target_name_ = target_name
      @_target_      = package.setup_tempfile(target_name, mode)
      @_proxy_       = Proxy.new(self)
      @_chain_       = false
      @attributes    = {}
    end
    
    # Closes target and returns self.
    def _close_
      _target_.close unless _target_.closed?
      self
    end
    
    # Returns true if the target is closed.
    def _is_closed_
      _target_.closed?
    end
    
    # Returns the current contents of target.
    def _result_
      if _target_.closed?
        _package_.content(_target_name_)
      else
        _target_.flush
        _target_.rewind
        _target_.read
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
      "${0%/#{_target_name_}}"
    end
    
    # The path to the named target as it should be referenced in the final
    # script, specifically target_name joined to package_dir.
    def target_path(target_name=_target_name_)
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
    # target_path to the resulting file.  The current target_name is updated
    # to target_name for the duration of the block.
    def capture_path(target_name, mode=0600, &block)
      tempfile = _package_.setup_tempfile(target_name, mode)
      tempfile << _capture_ do
        current = @_target_name_
        
        begin
          @_target_name_ = target_name
          instance_eval(&block)
        ensure
          @_target_name_ = current
        end
        
      end if block
      tempfile.close
      
      target_path target_name
    end
    
    # Writes input to the target using 'write'.  Returns self.
    def write(input)
      _target_.write input
      self
    end
    
    alias concat write
    
    # Writes input to the target using 'puts'.  Returns self.
    def writeln(input)
      _target_.puts input
      self
    end
    
    # Captures and returns output for the duration of a block.
    def _capture_
      current, redirect = @_target_, StringIO.new
      
      begin
        @_target_ = redirect
        yield
      ensure
        @_target_ = current
      end
      
      redirect.string
    end
    
    # Strips whitespace from the end of target. To do so the target is rewound
    # in chunks of n chars and then re-written without whitespace.  Returns
    # the stripped whitespace.
    #
    # Yields to a block if given, before performing the rstrip.
    def rstrip(n=10)
      yield if block_given?
      
      pos = _target_.pos
      n = pos if pos < n
      start = pos - n
      
      _target_.pos = start
      tail = _target_.read(n)
      whitespace = tail.slice!(/\s+\z/)
      
      _target_.pos = start
      _target_.truncate start
      
      if tail.length == 0 && start > 0
        # not done with rstrip, recurse.
        return "#{rstrip(n)}#{whitespace}"
      end
        
      write(tail)
      whitespace
    end
    
    # An array used for tracking indents currently in use.
    def _indents_
      @_indents_ ||= []
    end

    # Indents the output of the block.  Indents may be nested. To prevent a
    # section from being indented, enclose it within _outdent_ which resets
    # indentation to nothing for the duration of a block.
    #
    # Example:
    #
    #   writeln 'a'
    #   _indent_ do
    #     writeln 'b'
    #     _outdent_ do
    #       writeln 'c'
    #       _indent_ do
    #         writeln 'd'
    #       end
    #       writeln 'c'
    #     end
    #     writeln 'b'
    #   end
    #   writeln 'a'
    #
    #   "\n" + _result_
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
    def _indent_(indent='  ', &block)
      _indents_ << _indents_.last.to_s + indent
      str = _capture_(&block)
      _indents_.pop

      unless str.empty?
        str.gsub!(/^/, indent)

        if _indents_.empty?
          _outdents_.each do |flag|
            str.gsub!(/#{flag}(\d+):(.*?)#{flag}/m) do
              $2.gsub!(/^.{#{$1.to_i}}/, '')
            end
          end
          _outdents_.clear
        end

        writeln str
      end

      self
    end

    # An array used for tracking outdents currently in use.
    def _outdents_
      @_outdents_ ||= []
    end

    # Resets indentation to nothing for a section of text indented by _indent_.
    #
    # === Notes
    #
    # Outdent works by setting a text flag around the outdented section; the flag
    # and indentation is later stripped out using regexps.  For that reason, be
    # sure flag is not something that will appear anywhere else in the section.
    #
    # The default flag is like ':outdent_N:' where N is a big random number.
    def _outdent_(flag=nil)
      current_indent = _indents_.last

      if current_indent.nil?
        yield
      else
        flag ||= ":outdent_#{rand(10000000)}:"
        _outdents_ << flag

        write "#{flag}#{current_indent.length}:#{rstrip}"
        _indents_ << ''

        yield

        _indents_.pop
        write "#{flag}#{rstrip}"
      end

      self
    end
    
    # Sets _is_chain_ to true and calls the method (thereby allowing the
    # method to invoke chain-specific behavior).  Chain is invoked via the
    # _chain_proxy_ which is returned by helper methods.
    def _chain_(method_name, *args, &block)
      @_chain_ = true
      send(method_name, *args, &block)
    end
    
    # Returns true if the current context was invoked through chain.
    def _is_chain_
      @_chain_
    end
    
    # Sets chain to false and returns the proxy.
    def _chain_proxy_
      @_chain_ = false
      @_proxy_
    end
  end
end
