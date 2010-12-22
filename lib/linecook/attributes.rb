module Linecook
  class Attributes
    class << self
      def nest_hash
        Hash.new {|hash, key| hash[key] = nest_hash }
      end
    end
    
    attr_reader :attrs
    attr_reader :user_attrs
    
    def initialize(user_attrs={})
      @user_attrs = user_attrs
      reset(true)
    end
    
    def current
      @current ||= serial_merge(attrs, user_attrs)
    end
    
    def reset(full=true)
      @attrs = self.class.nest_hash if full
      @current = nil
    end
    
    private
    
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