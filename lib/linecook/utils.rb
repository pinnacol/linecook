module Linecook
  module Utils
    module_function

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

    def camelize(str)
      str.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
    end

    def underscore(str)
      str.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
    end

    # Looks up the specified constant. A block may be given to look up missing
    # constants; the last existing const and any non-existant constant names
    # are yielded to the block, which is expected to return the desired
    # constant.  For instance:
    #
    #   module ConstName; end
    #   Constant.constantize('ConstName')                     # => ConstName
    #   Constant.constantize('Non::Existant') { ConstName }   # => ConstName
    #
    # Raises a NameError for invalid/missing constants.
    def constantize(const_name) # :yields: const, missing_const_names
      unless  /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ const_name
        raise NameError, "#{const_name.inspect} is not a valid constant name!"
      end

      const = Object
      constants = $1.split(/::/)

      while name = constants.shift
        begin
          const = const.const_get(name)
        rescue NameError
          raise $! unless block_given?
          constants.unshift(name)
          return yield(const, constants)
        end
      end

      const
    end
  end
end