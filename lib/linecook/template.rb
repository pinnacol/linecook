require 'ostruct'
require 'stringio'
require 'erb'

module Linecook
  class Template
    class << self
      def build(template, locals, template_path=nil)
        ERB.new(template).result(OpenStruct.new(locals).send(:binding))
      end
    end
    
    attr_reader :erbout
    
    def initialize
      @erbout = StringIO.new
    end
    
    # Returns self (not the underlying erbout storage that actually receives
    # the output lines).  In the ERB context, this method directs erb outputs
    # to Template#concat and into the redirect mechanism.
    def _erbout
      self
    end
    
    # Sets the underlying erbout storage to input.
    def _erbout=(input)
    end
    
    # Concatenates the specified input to the underlying erbout storage.
    def concat(input)
      erbout << input
      self
    end
    
    def capture(strip=true)
      current, redirect = erbout, StringIO.new
      
      begin
        @erbout = redirect
        yield
      ensure
        @erbout = current
      end
      
      str = redirect.string
      str.strip! if strip
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
    
    def rstrip(n=10)
      yield if block_given?
      
      pos = erbout.pos
      n = pos if pos < n
      start = pos - n
      
      erbout.pos = start
      tail = erbout.read(n).rstrip
      
      erbout.pos = start
      erbout.truncate start
      
      tail.length == 0 && start > 0 ? rstrip(n * 2) : concat(tail)
    end
    
    def close
      erbout.close unless closed?
      self
    end
    
    def closed?
      erbout.closed?
    end
    
    def result(&block)
      instance_eval(&block) if block
      
      erbout.flush
      erbout.rewind
      erbout.read
    end
  end
end