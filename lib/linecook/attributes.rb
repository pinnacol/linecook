require 'linecook/utils'

module Linecook
  class Attributes
    attr_reader :attrs
    attr_reader :env
    
    def initialize(env={})
      @env = env
      reset(true)
    end
    
    def current
      @current ||= Utils.serial_merge(attrs, env)
    end
    
    def reset(full=true)
      @attrs = Utils.nest_hash if full
      @current = nil
    end
  end
end