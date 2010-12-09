module LineCook
  class Attributes
    class << self
      def nest_hash
        Hash.new {|hash, key| hash[key] = nest_hash }
      end
    end
    
    attr_reader :default
    attr_reader :normal
    attr_reader :override
    attr_reader :user_attrs
    
    def initialize(user_attrs={})
      @user_attrs = user_attrs
      reset
    end
    
    def attrs(recalculate=false)
      @attrs   = nil if recalculate
      @attrs ||= serial_merge(default, normal, override, user_attrs)
    end
    
    def reset(full=true)
      if full
        @default  = self.class.nest_hash
        @normal   = self.class.nest_hash
        @override = self.class.nest_hash
      end
      
      @attrs = nil
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