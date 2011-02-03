require 'linecook/utils'

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
      
      # Recursively disables automatic nesting of nest_hash hashes. Returns a
      # copy of the source with auto-nesting turned off (ie the source itself
      # will still auto-nest).
      def disable_nest_hash(source)
        if source.default_proc == NEST_HASH_PROC
          target = {}
          source.each_pair do |key, value|
            target[key] = value.kind_of?(Hash) ? disable_nest_hash(value) : value
          end
          target
        else
          source.dup
        end
      end
    end
    
    # An auto-filling nested hash
    attr_reader :attrs
    
    def initialize
      @attrs = Attributes.nest_hash
    end
    
    # Returns a copy of attrs with nesting turned off.
    def to_hash
      Attributes.disable_nest_hash(attrs)
    end
  end
end