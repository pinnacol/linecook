require 'linecook/utils'

module Linecook
  
  # Attributes provides a context for specifying default env attributes, on
  # top of which is merged the user env.  For example:
  #
  #   env = {'a' => 'A'}
  #   attributes = Attributes.new(user_env)
  #   attributes.instance_eval %{
  #     attrs['a'] = '-'
  #     attrs['b'] = 'B'
  #   }
  #
  #   attributes.current
  #   # => {'a' => 'A', 'b' => 'B'}
  #
  # Note that attrs is an auto-filling nested hash, making it easy to set
  # nested attributes, but it is not indifferent, meaning you do need to
  # differentiate between symbols and strings.  Normally strings are
  # preferred.
  #
  #   attributes = Attributes.new
  #   attributes.instance_eval %{
  #     attrs[:a]       = :A
  #     attrs['a']['b'] = 'B'
  #   }
  #
  #   attributes.current
  #   # => {:a => :A, 'a' => {'b' => 'B'}}
  #
  class Attributes
    
    # A hash of overriding attributes
    attr_reader :env
    
    # An auto-filling nested hash, used to specify default env attributes
    attr_reader :attrs
    
    def initialize(env={})
      @env = env
      @attrs = Utils.nest_hash
    end
    
    # The current env, comprising a deep merge of attrs and env.
    def current
      Utils.serial_merge(attrs, env)
    end
  end
end