# Generated by Linecook

module Linecook
  module Os
    # Defines POSIX-compliant functionality, based on the {IEEE 1003.1-2008
    # standard }[http://pubs.opengroup.org/onlinepubs/9699919799].  See the online
    # documentation for:
    #
    # * {POSIX Shell Command Language
    #   }[http://pubs.opengroup.org/onlinepubs/9699919799/utilities/xcu_chap02.html]
    # * {Special Built-in Utilities
    #   }[http://pubs.opengroup.org/onlinepubs/9699919799/idx/sbi.html]
    # * {Standard Utilties
    #   }[http://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html]
    #
    # In addition, the {Shell Hater's Handbook}[http://shellhaters.heroku.com/]
    # provides a nice index of the relevant information.
    #
    module Posix
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

      # Adds a redirect to append stdout to a file.
      def append(path=nil)
        redirect(nil, path || '/dev/null', '>>')
        _chain_proxy_
      end

      def _append(*args, &block) # :nodoc:
        str = capture { append(*args, &block) }
        str.strip!
        str
      end

      # Exit from for, while, or until loop.
      # {[Spec]}[http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_15]
      def break_()
        #  break
        #  
        write "break\n"

        _chain_proxy_
      end

      def _break_(*args, &block) # :nodoc:
        str = capture { break_(*args, &block) }
        str.strip!
        str
      end

      # Adds a check that ensures the last exit status is as indicated. Note that no
      # check will be added unless check_status_function is added beforehand.
      def check_status(expect_status=0, fail_status='$?')
        #  <% if function?('check_status') %>
        #  check_status <%= expect_status %> $? <%= fail_status %> $LINENO
        #  
        #  <% end %>
        if function?('check_status') 
        write "check_status "; write(( expect_status ).to_s); write " $? "; write(( fail_status ).to_s); write " $LINENO\n"
        write "\n"
        end 
        _chain_proxy_
      end

      def _check_status(*args, &block) # :nodoc:
        str = capture { check_status(*args, &block) }
        str.strip!
        str
      end

      # Defines the check status function.
      def check_status_function()
        function('check_status', nil) do |expected, actual, error, message|
          message.default = '?'
          
          if_ actual.ne(expected) do
            writeln %{echo [#{actual}] #{command_name}:#{message}}
            exit_ error
          end
          
          else_ do
            return_ actual
          end
        end
        _chain_proxy_
      end

      def _check_status_function(*args, &block) # :nodoc:
        str = capture { check_status_function(*args, &block) }
        str.strip!
        str
      end

      # Writes a comment.
      def comment(str)
        #  # <%= str %>
        #  
        write "# "; write(( str ).to_s); write "\n"

        _chain_proxy_
      end

      def _comment(*args, &block) # :nodoc:
        str = capture { comment(*args, &block) }
        str.strip!
        str
      end

      # Continue for, while, or until loop.
      # {[Spec]}[http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_17]
      def continue_()
        #  continue
        #  
        write "continue\n"

        _chain_proxy_
      end

      def _continue_(*args, &block) # :nodoc:
        str = capture { continue_(*args, &block) }
        str.strip!
        str
      end

      # Chains to if_ to make an else-if statement.
      def elif_(expression)
        unless match = _rewrite_(/(\s+)(fi\s*)/)
          raise "elif_ used outside of if_ statement"
        end
        #  <%= match[1] %>
        #  elif <%= expression %>
        #  then
        #  <% indent { yield } %>
        #  <%= match[2] %>
        write(( match[1] ).to_s)
        write "elif "; write(( expression ).to_s); write "\n"
        write "then\n"
        indent { yield } 
        write(( match[2] ).to_s)
        _chain_proxy_
      end

      def _elif_(*args, &block) # :nodoc:
        str = capture { elif_(*args, &block) }
        str.strip!
        str
      end

      # Chains to if_ or unless_ to make an else statement.
      def else_()
        unless match = _rewrite_(/(\s+)(fi\s*)/)
          raise "else_ used outside of if_ statement"
        end
        #  <%= match[1] %>
        #  else
        #  <% indent { yield } %>
        #  <%= match[2] %>
        write(( match[1] ).to_s)
        write "else\n"
        indent { yield } 
        write(( match[2] ).to_s)
        _chain_proxy_
      end

      def _else_(*args, &block) # :nodoc:
        str = capture { else_(*args, &block) }
        str.strip!
        str
      end

      # Executes a command and checks the output status. Quotes all non-option args
      # that aren't already quoted. Accepts a trailing hash which will be transformed
      # into command line options.
      def execute(command, *args)
        if _chain_?
          _rewrite_(trailer)
          write ' | '
        end
        #  <%= command_str(command, *args) %>
        #  
        #  <% check_status %>
        write(( command_str(command, *args) ).to_s)
        write "\n"
        check_status 
        _chain_proxy_
      end

      def _execute(*args, &block) # :nodoc:
        str = capture { execute(*args, &block) }
        str.strip!
        str
      end

      # Cause the shell to exit.
      # {[Spec]}[http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_21]
      def exit_(status=nil)
        #  <% if status.nil? %>
        #  exit
        #  <% else %>
        #  exit <%= status %>
        #  <% end %>
        #  
        if status.nil? 
        write "exit\n"
        else 
        write "exit "; write(( status ).to_s); write "\n"
        end 

        _chain_proxy_
      end

      def _exit_(*args, &block) # :nodoc:
        str = capture { exit_(*args, &block) }
        str.strip!
        str
      end

      # Assigns stdin to the file.
      def from(path)
        redirect(nil, path, '<')
        _chain_proxy_
      end

      def _from(*args, &block) # :nodoc:
        str = capture { from(*args, &block) }
        str.strip!
        str
      end

      # Makes a heredoc statement surrounding the contents of the block.  Options:
      # 
      #   delimiter   the delimiter used, by default HEREDOC_n where n increments
      #   outdent     add '-' before the delimiter
      #   quote       quotes the delimiter
      def heredoc(options={})
        tail = _chain_? ? _rewrite_(trailer) {|m| write ' '; m[1].lstrip } : nil
        
        unless options.kind_of?(Hash)
          options = {:delimiter => options}
        end
        
        delimiter = options[:delimiter] || begin
          @heredoc_count ||= -1
          "HEREDOC_#{@heredoc_count += 1}"
        end
        #  <<<%= options[:outdent] ? '-' : ' '%><%= options[:quote] ? "\"#{delimiter}\"" : delimiter %><% outdent(" # :#{delimiter}:") do %>
        #  <% yield %>
        #  <%= delimiter %><% end %>
        #  
        #  <%= tail %>
        #  
        write "<<"; write(( options[:outdent] ? '-' : ' ').to_s); write(( options[:quote] ? "\"#{delimiter}\"" : delimiter ).to_s);  outdent(" # :#{delimiter}:") do ; write "\n"
        yield 
        write(( delimiter ).to_s);  end 
        write "\n"
        write(( tail ).to_s)

        _chain_proxy_
      end

      def _heredoc(*args, &block) # :nodoc:
        str = capture { heredoc(*args, &block) }
        str.strip!
        str
      end

      # Executes the block when the expression evaluates to zero.
      def if_(expression)
        #  if <%= expression %>
        #  then
        #  <% indent { yield } %>
        #  fi
        #  
        #  
        write "if "; write(( expression ).to_s); write "\n"
        write "then\n"
        indent { yield } 
        write "fi\n"
        write "\n"

        _chain_proxy_
      end

      def _if_(*args, &block) # :nodoc:
        str = capture { if_(*args, &block) }
        str.strip!
        str
      end

      # Makes a redirect statement.
      def redirect(source, target, redirection='>')
        source = source.nil? || source.kind_of?(Fixnum) ? source : "#{source} "
        target = target.nil? || target.kind_of?(Fixnum) ? "&#{target}" : " #{target}"
        
        match = _chain_? ? _rewrite_(trailer) : nil
        write " #{source}#{redirection}#{target}"
        write match[1] if match
        _chain_proxy_
      end

      def _redirect(*args, &block) # :nodoc:
        str = capture { redirect(*args, &block) }
        str.strip!
        str
      end

      # Return from a function.
      # {[Spec]}[http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_24]
      def return_(status=nil)
        #  <% if status.nil? %>
        #  return
        #  <% else %>
        #  return <%= status %>
        #  <% end %>
        #  
        if status.nil? 
        write "return\n"
        else 
        write "return "; write(( status ).to_s); write "\n"
        end 

        _chain_proxy_
      end

      def _return_(*args, &block) # :nodoc:
        str = capture { return_(*args, &block) }
        str.strip!
        str
      end

      # Write a comment to delimit sections.  The comment takes the format:
      # 
      #   #### name ###
      def section(name="")
        n = (78 - name.length)/2
        str = "-" * n
        #  #<%= str %><%= name %><%= str %><%= "-" if name.length % 2 == 1 %>
        #  
        write "#"; write(( str ).to_s); write(( name ).to_s); write(( str ).to_s); write(( "-" if name.length % 2 == 1 ).to_s); write "\n"

        _chain_proxy_
      end

      def _section(*args, &block) # :nodoc:
        str = capture { section(*args, &block) }
        str.strip!
        str
      end

      # Adds a redirect of stdout to a file.
      def to(path=nil)
        redirect(nil, path || '/dev/null')
        _chain_proxy_
      end

      def _to(*args, &block) # :nodoc:
        str = capture { to(*args, &block) }
        str.strip!
        str
      end

      # Executes the block when the expression evaluates to a non-zero value.
      def unless_(expression)
        if_("! #{expression}") { yield }
        _chain_proxy_
      end

      def _unless_(*args, &block) # :nodoc:
        str = capture { unless_(*args, &block) }
        str.strip!
        str
      end

      # Executes the block until the expression evaluates to zero.
      def until_(expression)
        #  until <%= expression %>
        #  do
        #  <% indent { yield } %>
        #  done
        #  
        #  
        write "until "; write(( expression ).to_s); write "\n"
        write "do\n"
        indent { yield } 
        write "done\n"
        write "\n"

        _chain_proxy_
      end

      def _until_(*args, &block) # :nodoc:
        str = capture { until_(*args, &block) }
        str.strip!
        str
      end

      # Set a variable.
      def variable(key, value)
        #  <%= key %>=<%= quote(value) %>
        #  
        #  
        write(( key ).to_s); write "="; write(( quote(value) ).to_s)
        write "\n"

        _chain_proxy_
      end

      def _variable(*args, &block) # :nodoc:
        str = capture { variable(*args, &block) }
        str.strip!
        str
      end

      # Executes the block while the expression evaluates to zero.
      def while_(expression)
        #  while <%= expression %>
        #  do
        #  <% indent { yield } %>
        #  done
        #  
        #  
        write "while "; write(( expression ).to_s); write "\n"
        write "do\n"
        indent { yield } 
        write "done\n"
        write "\n"

        _chain_proxy_
      end

      def _while_(*args, &block) # :nodoc:
        str = capture { while_(*args, &block) }
        str.strip!
        str
      end
    end
  end
end
