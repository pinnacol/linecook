require 'stringio'
require 'erb'

module Linecook
  
  # Template provides a way to build text in code using ERB snippets compiled
  # into ruby code. For example:
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
  #   template = Template.new.extend Helper
  #   template.echo 'a', 'b c'
  #   template.echo 'X Y'.downcase, :z
  #
  #   "\n" + template.result
  #   # => %{
  #   # echo 'a b c'
  #   # echo 'x y z'
  #   # }
  #
  # Templates control the _erbout context, such that reformatting is possible
  # before any content is emitted. This allows such things as indentation.
  # Combine with instance_eval to make helpers into a tidy DSL:
  #
  #   template = Template.new.extend Helper
  #   template.instance_eval do
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
  class Template
    
    # An IO-type target to recieve any template output.
    attr_reader :target
    
    def initialize(target=StringIO.new)
      @target = target
    end
    
    # Returns self.  In the context of a compiled ERB helper, this method
    # directs output to Template#concat and thereby into target.  This trick
    # is what allows Template to capture and reformat output.
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
    # resolves to Template#_erbout, and thus Template gains control of the
    # output.
    def _erbout=(input)
    end
    
    # Pushes input to the target using '<<'.  Returns self.
    def concat(input)
      target << input
      self
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
    
    # Flushes target, rewinds, and reads the contents of target.
    def result
      target.flush
      target.rewind
      target.read
    end
  end
end