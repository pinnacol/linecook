require 'linecook/utils'

module Linecook
  class Attributes
    attr_reader :attrs
    attr_reader :context
    
    def initialize(context={})
      @context = context
      reset(true)
    end
    
    def current
      @current ||= Utils.serial_merge(attrs, context)
    end
    
    def reset(full=true)
      @attrs = Utils.nest_hash if full
      @current = nil
    end
  end
end