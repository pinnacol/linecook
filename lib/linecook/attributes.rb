require 'linecook/hash_utils'

module Linecook
  class Attributes
    attr_reader :attrs
    attr_reader :context
    
    def initialize(context={})
      @context = context
      reset(true)
    end
    
    def current
      @current ||= HashUtils.serial_merge(attrs, context)
    end
    
    def reset(full=true)
      @attrs = nest_hash if full
      @current = nil
    end
    
    private
    
    def nest_hash # :nodoc:
      Hash.new {|hash, key| hash[key] = nest_hash }
    end
  end
end