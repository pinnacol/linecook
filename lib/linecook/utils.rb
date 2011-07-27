module Linecook
  module Utils
    module_function

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

    def constantize(const_name)
      constants = camelize(const_name).split(/::/)

      const = Object
      while name = constants.shift
        const = const.const_get(name)
      end

      const
    end
  end
end