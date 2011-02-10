require 'yaml'

module Linecook
  module Utils
    module_function
    
    def load_config(path)
      (path ? YAML.load_file(path) : nil) || {}
    end
    
    def arrayify(obj)
      case obj
      when nil    then []
      when String then obj.split(':')
      else obj
      end
    end
    
    def hashify(obj)
      case obj
      when Hash then obj
      when nil  then {}
      when Array
        hash = {}
        obj.each {|entry| hash[entry] = entry }
        hash
      
      when String 
        hashify obj.split(':')
      
      else nil
      end
    end
    
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