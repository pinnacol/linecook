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
    # The recipe target
    attr_reader :_target_

    # The current recipe target
    attr_reader :target

    def initialize(target=StringIO.new)
      @_target_ = target
      @target   = target

      @indents     = []
      @outdents    = []

      if block_given?
        instance_eval(&Proc.new)
      end
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

    # Returns the contents of target.
    def _result_
      target.flush
      target.rewind
      target.read
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
  end
end