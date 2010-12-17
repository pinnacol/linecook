require 'ostruct'
require 'stringio'
require 'erb'

module LineCook
  class Templater
    class << self
      def build(template, locals, template_path=nil)
        ERB.new(template).result(OpenStruct.new(locals).send(:binding))
      end
    end
    
    attr_reader :target
    
    def initialize
      @target = StringIO.new
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
      current, redirect = target, StringIO.new
      
      begin
        @target = redirect
        yield
      ensure
        @target = current
      end
      
      str = redirect.string
      str.strip!
      str
    end
    
    def indent(indent='  ', &block)
      capture(&block).split("\n").each do |line|
        concat "#{indent}#{line}\n"
      end
      self
    end
    
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
    
    def module_nest(const_name, indent="  ", line_sep="\n")
      nestings = const_name.split(/::/).collect {|name| ["module #{name}", "end"]} 
      nestings << {:indent => indent, :line_sep => line_sep}
      
      nest(*nestings) { yield }
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
    
    def close
      target.close unless closed?
      self
    end
    
    def closed?
      target.closed?
    end
    
    def to_s
      target.flush
      target.rewind
      target.read
    end
  end
end