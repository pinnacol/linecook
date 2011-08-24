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

    # Looks up the specified constant under const. A block may be given to
    # manually look up missing constants; the last existing const and any
    # non-existant constant names are yielded to the block, which is expected
    # to return the desired constant.  For instance:
    #
    #   module ConstName; end
    #   Constant.constantize('ConstName')                     # => ConstName
    #   Constant.constantize('Non::Existant') { ConstName }   # => ConstName
    #
    # Raises a NameError for invalid/missing constants.
    def constantize(const_name, const=Object) # :yields: const, missing_const_names
      unless  /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ const_name
        raise NameError, "#{const_name.inspect} is not a valid constant name!"
      end

      constants = $1.split(/::/)
      while !constants.empty?
        unless const_is_defined?(const, constants[0])
          if block_given? 
            return yield(const, constants)
          else
            raise NameError.new("uninitialized constant #{const_name}", constants[0])
          end
        end
        const = const.const_get(constants.shift)
      end
      const
    end

    # helper method.  Determines if the named constant is defined in const.
    # The implementation has to be different for ruby 1.9 due to changes
    # in the API.
    case RUBY_VERSION
    when /^1.9/
      def const_is_defined?(const, const_name) # :nodoc:
        const.const_defined?(const_name, false)
      end
    else
      def const_is_defined?(const, const_name) # :nodoc:
        const.const_defined?(const_name)
      end
    end
  end
end