require 'erb'
require 'tilt'
require 'linecook/attributes'
require 'linecook/cookbook'
require 'linecook/package'
require 'linecook/proxy'
require 'linecook/utils'

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
  #   recipe  = Recipe.new do
  #     extend Helper
  #     echo 'a', 'b c'
  #     echo 'X Y'.downcase, :z
  #   end
  #
  #   "\n" + recipe._result_
  #   # => %{
  #   # echo 'a b c'
  #   # echo 'x y z'
  #   # }
  #
  class Recipe
    # The recipe package
    attr_reader :_package_

    # The recipe cookbook
    attr_reader :_cookbook_

    # The recipe target
    attr_reader :_target_

    # The current recipe target
    attr_reader :target

    # The recipe proxy
    attr_reader :_proxy_

    def initialize(package=Package.new, cookbook=Cookbook.new, target=StringIO.new)
      @_package_ = package
      @_cookbook_ = cookbook
      @_target_ = target
      @target   = target
      @_proxy_  = Proxy.new(self)
      @_chain_  = false
      @attributes  = {}
      @indents  = []
      @outdents = []

      if block_given?
        instance_eval(&Proc.new)
      end
    end

    # Loads the specified attributes file and merges the results into attrs. A
    # block may be given to specify attrs as well; it will be evaluated in the
    # context of an Attributes instance.
    def attributes(path=nil, &block)
      attributes = Attributes.new

      unless path.nil?
        if full_path = _cookbook_.find(:attributes, path, Attributes::EXTNAMES)
          attributes.load_attrs(full_path)
        end
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
      @attrs ||= Utils.deep_merge(@attributes, _package_.env)
    end

    # Looks up and extends self with the specified helper.
    def helper(*helper_names)
      helper_names.each do |helper_name|
        require Utils.underscore(helper_name)
        extend Utils.constantize(helper_name)
      end
      self
    end

    # Returns the path to the target as used at runtime (vs compile time). 
    # Mainly target_path is a hook for helpers to override - by default it
    # simply returns target_name.
    def target_path(target_name)
      target_name
    end

    # Finds a source path, adds it to the package, and returns a target path.
    # Options specify export options, and the following:
    #
    #   key            value
    #   :target_name   The name of the file in the package (default guessed
    #                  by _guess_target_name_)
    #
    # See _file_source_path_ for how source_name is resolved to a source path.
    def file_path(source_name, options={})
      source_path = _file_source_path_(source_name)
      target_name = options.delete(:target_name) || _guess_target_name_(source_path)

      _package_.register target_name, source_path, options
      target_path target_name
    end

    # Finds a recipe, compiles it, adds it to the package, and returns a
    # target path. Options specify export options, and the following:
    #
    #   key            value
    #   :target_name   The name of the recipe result in the package (default
    #                  guessed by _guess_recipe_name_)
    #
    # See _recipe_source_path_ for how source_name is resolved to a recipe.
    def recipe_path(source_name, options={})
      source_path = _recipe_source_path_(source_name)
      target_name = options.delete(:target_name) || _guess_recipe_name_(source_path)
      target = _package_.add(target_name, options)

      recipe = Recipe.new(_package_, _cookbook_, target)
      recipe.instance_eval File.read(source_path), source_path

      target.close unless target.closed?
      target_path target_name
    end

    # Finds a template, compiles it, adds it to the package, and returns a
    # target path. Options specify export options, and the following:
    #
    #   key            value
    #   :target_name   The name of the template result in the package (default
    #                  guessed by _guess_template_name_)
    #   :locals        The locals for the template (default attrs)
    #
    # See _template_source_path_ for how source_name is resolved to a
    # template.
    def template_path(source_name, options={})
      source_path = _template_source_path_(source_name)
      target_name = options.delete(:target_name) || _guess_template_name_(source_path)
      locals = options.delete(:locals) || attrs

      capture_path(target_name, options) { write render(source_path, locals) }
    end

    # Captures output to target for a block and adds the result to _package_
    # at target_name.  Options specify export options.
    def capture_path(target_name, options={})
      target = _package_.add(target_name, options)

      _capture_(target) { yield } if block_given?

      target.close unless target.closed?
      target_path target_name
    end

    def render(source_name, locals=attrs)
      source_path = _template_source_path_(source_name)
      Tilt.new(source_path).render(Object.new, locals)
    end

    # Captures and returns output for the duration of a block by redirecting
    # target to a temporary buffer.
    def capture
      _capture_ { yield }.string
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

    # Indents the output of the block.  Indents may be nested. To prevent a
    # section from being indented, enclose it within outdent which resets
    # indentation to nothing for the duration of a block.
    #
    # Example:
    #
    #   recipe = Recipe.new do
    #     writeln 'a'
    #     indent do
    #       writeln 'b'
    #       outdent do
    #         writeln 'c'
    #         indent do
    #           writeln 'd'
    #         end
    #         writeln 'c'
    #       end
    #       writeln 'b'
    #     end
    #     writeln 'a'
    #   end
    #
    #   "\n" + recipe._result_
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
    def indent(indent='  ')
      @indents << @indents.last.to_s + indent
      str = capture { yield }
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

        write "#{flag}#{current_indent.length}:#{_rstrip_}"
        @indents << ''

        yield

        @indents.pop

        write "#{flag}#{_rstrip_}"
      end

      self
    end

    # Captures a block of output and concats to the named callback.
    def callback(name)
      target = _package_.callback(name)
      _capture_(target) { yield }
    end

    # Writes the specified callback to the current target.
    def write_callback(name, close=true)
      target = _package_.callback(name)
      target.rewind

      write target.read

      if close
        target.close
      end
    end

    def _guess_target_name_(source_path)
      File.basename(source_path)
    end

    def _guess_template_name_(source_path)
      _guess_target_name_(source_path).chomp(File.extname(source_path))
    end

    def _guess_recipe_name_(source_path)
      _guess_target_name_(source_path).chomp('.rb')
    end

    def _file_source_path_(source_name)
      _cookbook_.find(:files, source_name)
    end

    def _template_source_path_(source_name)
      _cookbook_.find(:templates, source_name, ['.erb'])
    end

    def _recipe_source_path_(source_name)
      _cookbook_.find(:recipes, source_name, ['.rb'])
    end

    def _compile_(recipe_name)
      source_path = _recipe_source_path_(recipe_name)
      instance_eval File.read(source_path), source_path
      self
    end

    # Returns the contents of target.
    def _result_
      target.flush
      target.rewind
      target.read
    end

    # Captures output to the target for the duration of a block.  Returns the
    # capture target.
    def _capture_(target=StringIO.new)
      current = @target

      begin
        @target = target
        yield
      ensure
        @target = current
      end

      target
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
    def _rewrite_(pattern)
      if match = pattern.match(_result_)
        start = match.begin(0)
        target.pos = start
        target.truncate start
      end

      block_given? ? yield(match) : match
    end

    # Strips whitespace from the end of target and returns the stripped
    # whitespace, or an empty string if no whitespace is available.
    def _rstrip_
      match = _rewrite_(/\s+\z/)
      match ? match[0] : ''
    end

    # Sets _chain_? to return true and calls the method (thereby allowing the
    # method to invoke chain-specific behavior).  Calls to _chain_ are
    # typically invoked via _proxy_.
    def _chain_(method_name, *args, &block)
      @_chain_ = true
      send(method_name, *args, &block)
    end

    # Returns true if the current context was invoked through chain.
    def _chain_?
      @_chain_
    end

    # Sets _chain_? to return false and returns the proxy.
    def _chain_proxy_
      @_chain_ = false
      _proxy_
    end
  end
end