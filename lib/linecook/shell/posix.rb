require 'erb'

# Generated by Linecook, do not edit.
module Linecook
module Shell
module Posix
# :stopdoc:
HEREDOC_LINE = __LINE__ + 2
HEREDOC = "self." + ERB.new(<<'END_OF_TEMPLATE', nil, '<>').src
<% end_of_file = "END_OF_FILE_#{(@heredoc_count ||= 0) += 1}" %> << <%= end_of_file %>
<% yield %>

<%= end_of_file %>
END_OF_TEMPLATE
# :startdoc:

# Makes a heredoc statement surrounding the contents of the block.
def heredoc
  eval(HEREDOC, binding, __FILE__, HEREDOC_LINE)
  nil
end

def _heredoc(*args, &block) # :nodoc:
  capture { heredoc(*args, &block) }
end

# :stopdoc:
NOT_IF_LINE = __LINE__ + 2
NOT_IF = "self." + ERB.new(<<'END_OF_TEMPLATE', nil, '<>').src
only_if("! #{cmd}", &block)
END_OF_TEMPLATE
# :startdoc:

def not_if(cmd, &block)
  eval(NOT_IF, binding, __FILE__, NOT_IF_LINE)
  nil
end

def _not_if(*args, &block) # :nodoc:
  capture { not_if(*args, &block) }
end

# :stopdoc:
ONLY_IF_LINE = __LINE__ + 2
ONLY_IF = "self." + ERB.new(<<'END_OF_TEMPLATE', nil, '<>').src
if <%= cmd %>
then
<% indent { yield } %>
fi

END_OF_TEMPLATE
# :startdoc:

def only_if(cmd)
  eval(ONLY_IF, binding, __FILE__, ONLY_IF_LINE)
  nil
end

def _only_if(*args, &block) # :nodoc:
  capture { only_if(*args, &block) }
end

# :stopdoc:
SET_LINE = __LINE__ + 2
SET = "self." + ERB.new(<<'END_OF_TEMPLATE', nil, '<>').src
<% if block_given? %>
<% reset_file = "LINECOOK_RESET_OPTIONS_#{next_count}" %>
<%= reset_file %>=`mktemp /tmp/line_cook_reset_fileXXXXXX`
set -o | sed 's/\(.*\)	on/set -o \1/' | sed 's/\(.*\)	off/set +o \1/' > $<%= reset_file %>
<% end %><% options.keys.sort_by {|opt| opt.to_s }.each do |opt| %>
set <%= options[opt] ? '-' : '+' %>o <%= opt %>
<% end %>
<% if block_given? %>

<% indent { yield }  %>

source $<%= reset_file %>
<% end %>

END_OF_TEMPLATE
# :startdoc:

# Sets bash options for the duration of a block.  If no block is given,
# set simply sets the options as specified.
def set(options)
  eval(SET, binding, __FILE__, SET_LINE)
  nil
end

def _set(*args, &block) # :nodoc:
  capture { set(*args, &block) }
end

# :stopdoc:
UNSET_LINE = __LINE__ + 2
UNSET = "self." + ERB.new(<<'END_OF_TEMPLATE', nil, '<>').src
<% keys.each do |key| %>
unset <%= key %>
<% end %>
END_OF_TEMPLATE
# :startdoc:

# Unsets a list of variables.
def unset(*keys)
  eval(UNSET, binding, __FILE__, UNSET_LINE)
  nil
end

def _unset(*args, &block) # :nodoc:
  capture { unset(*args, &block) }
end
end
end
end
