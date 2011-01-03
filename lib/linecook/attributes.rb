module Linecook
  class Attributes
    attr_reader :attrs
    attr_reader :context
    
    def initialize(context={})
      @context = context
      reset(true)
    end
    
    def current
      @current ||= serial_merge(attrs, context)
    end
    
    def reset(full=true)
      @attrs = nest_hash if full
      @current = nil
    end
    
    private
    
    def nest_hash # :nodoc:
      Hash.new {|hash, key| hash[key] = nest_hash }
    end
    
    def serial_merge(*hashes) # :nodoc:
      attrs = {}
      while overrides = hashes.shift
        attrs = deep_merge(attrs, overrides)
      end
      attrs
    end
    
    def deep_merge(a, b) # :nodoc:
      b.each_pair do |key, current|
        previous = a[key]
        a[key] = deep_merge?(previous, current) ? deep_merge(previous, current) : current
      end
      
      a
    end
    
    def deep_merge?(previous, current) # :nodoc:
      current.kind_of?(Hash) && previous.kind_of?(Hash)
    end
  end
end