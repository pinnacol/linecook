module Linecook
  module HashUtils
    module_function
    
    def serial_merge(*hashes)
      attrs = {}
      while overrides = hashes.shift
        attrs = deep_merge(attrs, overrides)
      end
      attrs
    end
    
    def deep_merge(a, b)
      b.each_pair do |key, current|
        previous = a[key]
        a[key] = deep_merge?(previous, current) ? deep_merge(previous, current) : current
      end
      
      a
    end
    
    def deep_merge?(previous, current)
      current.kind_of?(Hash) && previous.kind_of?(Hash)
    end
  end
end