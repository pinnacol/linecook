require 'erb'

# Generated by Linecook, do not edit.
module Linecook
module Shell
module Unix
# :stopdoc:
CHMOD_LINE = __LINE__ + 2
CHMOD = "self." + ERB.new(<<'END_OF_TEMPLATE', nil, '<>').src
<% if mode %>
chmod <%= mode %> "<%= target %>"
<% check_status %>
<% end %>
END_OF_TEMPLATE
# :startdoc:

def chmod(target, mode=nil)
  eval(CHMOD, binding, __FILE__, CHMOD_LINE)
  nil
end

def _chmod(*args, &block) # :nodoc:
  capture { chmod(*args, &block) }
end

# :stopdoc:
CHOWN_LINE = __LINE__ + 2
CHOWN = "self." + ERB.new(<<'END_OF_TEMPLATE', nil, '<>').src
<% if user || group %>
chown <%= user %>:<%= group %> "<%= target %>"
<% check_status %>
<% end %>
END_OF_TEMPLATE
# :startdoc:

def chown(target, user=nil, group=nil)
  eval(CHOWN, binding, __FILE__, CHOWN_LINE)
  nil
end

def _chown(*args, &block) # :nodoc:
  capture { chown(*args, &block) }
end

# :stopdoc:
ECHO_LINE = __LINE__ + 2
ECHO = "self." + ERB.new(<<'END_OF_TEMPLATE', nil, '<>').src
echo '<%= args.join(" ") %>'
END_OF_TEMPLATE
# :startdoc:

# Echos input
def echo(*args)
  eval(ECHO, binding, __FILE__, ECHO_LINE)
  nil
end

def _echo(*args, &block) # :nodoc:
  capture { echo(*args, &block) }
end

# :stopdoc:
LN_S_LINE = __LINE__ + 2
LN_S = "self." + ERB.new(<<'END_OF_TEMPLATE', nil, '<>').src
ln -sf "<%= source %>" "<%= target %>"
<% check_status %>

END_OF_TEMPLATE
# :startdoc:

def ln_s(source, target)
  eval(LN_S, binding, __FILE__, LN_S_LINE)
  nil
end

def _ln_s(*args, &block) # :nodoc:
  capture { ln_s(*args, &block) }
end

# :stopdoc:
RM_LINE = __LINE__ + 2
RM = "self." + ERB.new(<<'END_OF_TEMPLATE', nil, '<>').src
<% only_if %Q{ls -l "#{path}"} do %>
rm <% if opts %><%= opts %> <% end %>"<%= path %>"
<% end %>
END_OF_TEMPLATE
# :startdoc:

def rm(path, opts=nil)
  eval(RM, binding, __FILE__, RM_LINE)
  nil
end

def _rm(*args, &block) # :nodoc:
  capture { rm(*args, &block) }
end
end
end
end
