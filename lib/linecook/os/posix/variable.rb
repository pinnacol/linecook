module Linecook
  module Os
    module Posix
      class Variable
        attr_accessor :varname
        attr_accessor :default

        def initialize(varname, default=nil)
          @varname = varname.to_s
          @default = default
        end

        def lstrip(pattern)
          "${#{varname}##{pattern}}"
        end

        def llstrip(pattern)
          "${#{varname}###{pattern}}"
        end

        def rstrip(pattern)
          "${#{varname}%#{pattern}}"
        end

        def rrstrip(pattern)
          "${#{varname}%%#{pattern}}"
        end

        def sub(pattern, replacement)
          "${#{varname}/#{pattern}/#{replacement}}"
        end

        def gsub(pattern, replacement)
          "${#{varname}//#{pattern}/#{replacement}}"
        end

        def length
          "${##{varname}}"
        end

        def substring(offset, length=nil)
          length ? "${#{varname}:#{offset}:#{length}}": "${#{varname}:#{offset}}"
        end

        def eq(another)
          "[ #{self} -eq #{another} ]"
        end

        def ne(another)
          "[ #{self} -ne #{another} ]"
        end

        def gt(another)
          "[ #{self} -gt #{another} ]"
        end

        def lt(another)
          "[ #{self} -lt #{another} ]"
        end

        def ==(another)
          "[ #{self} = #{another} ]"
        end

        # def !=(another)
        #   "[ #{self} != #{another} ]"
        # end

        def >(another)
          "[ #{self} > #{another} ]"
        end

        def <(another)
          "[ #{self} < #{another} ]"
        end

        def null?
          "[ -z #{self} ]"
        end

        def not_null?
          "[ -n #{self} ]"
        end

        def to_s
          default.nil? ? "$#{varname}" : "${#{varname}:-#{default}}"
        end
      end
    end
  end
end