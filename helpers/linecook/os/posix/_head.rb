require 'linecook/os/posix/variable'
require 'linecook/os/posix/utilities'
include Utilities

# Returns "$0", the current command name.
def command_name
  Variable.new(0)
end

# Returns the command directory (ie the directory containing $0).
def command_dir
  "${0%/*}"
end

def set_package_dir(dir)
  writeln "export LINECOOK_PACKAGE_DIR=#{quote(dir)}"
end

# Returns an expression that evaluates to the package dir.
def package_dir
  '${LINECOOK_PACKAGE_DIR:-$PWD}'
end

def target_path(target_name)
  File.join(package_dir, target_name)
end

# Encloses the arg in quotes, unless already quoted (see quoted?).
def quote(str)
  quoted?(str) ? str : "\"#{str}\""
end

# Returns true if the str is quoted (either by quotes or apostrophes).
def quoted?(str)
  str =~ /\A".*"\z/ || str =~ /\A'.*'\z/ ? true : false
end

# Encloses the arg in quotes unless the arg is an option or already quoted
# (see option? and quoted?).
def option_quote(str)
  option?(str) ? str : quote(str)
end

# Returns true if the str is an option (ie it begins with - or +).
def option?(str)
  c = str[0]
  c == ?- || c == ?+
end

# Formats a command line command.  Arguments are quoted. If the last arg is a
# hash, then it will be formatted into options using format_options and
# prepended to args.
def command_str(command, *args)
  opts = args.last.kind_of?(Hash) ? args.pop : {}
  args.compact!
  args.collect! {|arg| option_quote(arg.to_s) }
  
  args = options_str(opts) + args
  args.unshift(command)
  args.join(' ')
end

# Formats a hash key-value string into command line options using the
# following heuristics:
#
# * Prepend '--' to mulit-char keys and '-' to single-char keys (unless they
#   already start with '-').
# * For true values return the '--key'
# * For false/nil values return nothing
# * For all other values, quote (unless already quoted) and return '--key
#  "value"'
#
# In addition, key formatting is performed on non-string keys (typically
# symbols) such that underscores are converted to dashes, ie :some_key =>
# 'some-key'.  Note that options are sorted, such that short options appear
# after long options, and so should 'win' given typical option processing.
def options_str(opts)
  options = []
  
  opts.each do |(key, value)|
    unless key.kind_of?(String)
      key = key.to_s.gsub('_', '-')
    end
    
    unless key[0] == ?-
      prefix = key.length == 1 ? '-' : '--'
      key = "#{prefix}#{key}"
    end
    
    case value
    when true
      options << key
    when false, nil
      next
    else
      options << "#{key} #{quote(value.to_s)}"
    end
  end
  
  options.sort
end

# A hash of functions defined for self.
def functions
  @functions ||= {}
end

# Defines a function from the block.  The block content is indented and
# cleaned up some to make a nice function definition.
def function(name, method_name=name)
  str = capture { indent { yield(*signature(Proc.new.arity)) } }
  function = %{#{name}() {\n#{str.chomp("\n")}\n}}
  
  if function?(name)
    unless functions[name] == function
      raise "function already defined: #{name.inspect}"
    end
  else
    functions[name] = function
    
    if method_name
      instance_eval %{
        def self.#{method_name}(*args)
          execute '#{method_name}', *args
          _chain_proxy_
        end
      }
    end
  end
  
  writeln function
  name
end

# Returns true if a function with the given name is defined.
def function?(name)
  functions.has_key?(name)
end

# Returns an array of positional variables for use as inputs to a function
# block.  Splat blocks are supported; the splat expression behaves like $*.
def signature(arity)
  variables = Array.new(arity.abs) {|i| var(i+1) }
  
  if arity < 0
    # This works for defaults...
    # $(shift 1; echo ${*:-NONE})
    # You can't do this:
    # ${$(shift 1; echo $*):-NONE}
    variables[-1] = "$(shift #{arity.abs - 1}; echo $*)"
  end
  
  variables
end

def var(name)
  Variable.new(name)
end

def trailer
  /(\s*(?:\ncheck_status.*?\n\s*)?)\z/
end
