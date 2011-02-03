module Linecook
  
  # Attributes provides a context for specifying default attributes.  For
  # example:
  #
  #   attributes = Attributes.new
  #   attributes.instance_eval %{
  #     attrs['a'] = 'A'
  #     attrs['b']['c'] = 'C'
  #   }
  #
  #   attributes.to_hash
  #   # => {'a' => 'A', 'b' => {'c' => 'C'}}
  #
  # Note that attrs is an auto-filling nested hash, making it easy to set
  # nested attributes, but it is not indifferent, meaning you do need to
  # differentiate between symbols and strings.  Normally strings are
  # preferred.
  class Attributes
    # A proc used to create nest_hash hashes
    NEST_HASH_PROC = Proc.new do |hash, key|
      hash[key] = Hash.new(&NEST_HASH_PROC)
    end
    
    class << self
      # Returns an auto-filling nested hash.
      def nest_hash
        Hash.new(&NEST_HASH_PROC)
      end
      
      # Recursively disables automatic nesting of nest_hash hashes.
      def disable_nest_hash(hash)
        if hash.default_proc == NEST_HASH_PROC
          hash.default = nil
        end
        
        hash.each_pair do |key, value|
          if value.kind_of?(Hash)
            disable_nest_hash(value)
          end
        end
        
        hash
      end
    end
    
    # An auto-filling nested hash
    attr_reader :attrs
    
    def initialize
      @attrs = Attributes.nest_hash
    end
    
    # Disables automatic nesting and returns attrs.
    def to_hash
      Attributes.disable_nest_hash(attrs)
    end
  end
end