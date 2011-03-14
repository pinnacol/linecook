module Linecook
  # A proxy used to chain method calls back to a recipe.
  class Proxy
    def initialize(recipe)
      @recipe = recipe
    end
    
    # Proxies to recipe.chain.
    def method_missing(*args, &block)
      @recipe.chain(*args, &block)
    end
    
    # Returns an empty string, such that the proxy makes no text when it is
    # accidentally put into a target by a helper.
    def to_s
      ''
    end
  end
end