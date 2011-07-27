require 'linecook/command'
require 'linecook/utils'
require 'fileutils'
require 'erb'

module Linecook
  module Commands

    # :startdoc::desc generates a helper module
    #
    # Generates the specified helper module from a set of source files.  Each
    # source file becomes a method in the module, named after the source file
    # itself.
    #
    # The helper module will be generated under the outptut directory, by
    # default 'lib', in a file corresponding to const_name (which can also be
    # a constant path). By default, all files under the corresponding helpers
    # directory will be used as sources.  For example these are equivalent and
    # produce the Const::Name module in 'lib/const/name.rb':
    #
    #   $ linecook compile_helper Const::Name
    #   $ linecook compile_helper const/name
    #   $ linecook compile_helper const/name helpers/const/name/*
    #
    # == Source Files
    #
    # The contents of the source file are translated into code according to
    # the source file extname.
    #
    #   extname      translation
    #   .rb          file defines method body
    #   .erb         file defines an ERB template (compiled to ruby code)
    #
    # Source files can specify documenation and a method signature using a
    # standard header separated from the body by a double-dash.  For example
    # this:
    #
    #   [echo.erb]
    #   Echo arguments out to the target.
    #   (*args)
    #   --
    #   echo <%= args.join(' ') %>
    #
    # Is translated into something like:
    #
    #   # Echo arguments out to the target.
    #   def echo(*args)
    #     eval ERB.new("echo <%= args.join(' ') %>").src
    #   end
    #
    # A second method is also generated to return the result without writing
    # it to the target.  The latter method is prefixed by an underscore like:
    #
    #   # Return the output of echo, without writing to the target
    #   def _echo(*args)
    #     ...
    #   end
    #
    # Check and bang methods can be specified by adding -check and -bang to
    # the end of the file name.  These extensions are stripped off like:
    #
    #   [file-check.erb]   # => def file? ...
    #   [make-bang.rb]     # => def make! ...
    #
    # Otherwise the basename of the source file must be a word; non-word
    # basenames raise an error.
    #
    # == Section Files
    #
    # Special section files can be used to define non-standard code in the
    # following places:
    #
    #   [:header]
    #   module Const
    #     [:doc]
    #     module Name
    #       [:head]
    #       ...
    #       [:foot]
    #     end
    #   end
    #   [:footer]
    #
    # Section files are defined by prepending '_' to the file basename (like
    # path/to/_header.rb) and are not processed like other source files;
    # instead the contents are directly transcribed into the target file.
    class CompileHelper < Command
      config :output_dir, 'lib'   # -o : the output directory
      config :force, false        # -f : force creation
      config :quiet, false        # -q : print nothing

      include Utils

      def process(const_name, *sources)
        const_path = underscore(const_name)
        const_name = camelize(const_path)

        unless const_name?(const_name)
          raise "invalid constant name: #{const_name.inspect}"
        end

        sources = default_sources(const_path) if sources.empty?
        target  = File.expand_path(File.join(output_dir, "#{const_path}.rb"))

        if sources.empty?
          raise CommandError, "no sources specified (and none found under 'helpers/#{const_path}')"
        end

        if force || !FileUtils.uptodate?(target, sources)
          content = build(const_name, sources)

          target_dir = File.dirname(target)
          unless File.exists?(target_dir)
            FileUtils.mkdir_p(target_dir) 
          end

          File.open(target, 'w') {|io| io << content }
          $stdout.puts target unless quiet
        end

        target
      end

      # Returns the default source files for a given constant path, which are
      # all files under the 'project_dir/helpers/const_path' folder.
      def default_sources(const_path)
        pattern = File.join(project_dir, 'helpers', const_path, '*')
        sources = Dir.glob(pattern)
        sources.select {|path| File.file?(path) }
      end

      # returns true if const_name is a valid constant name.
      def const_name?(const_name) # :nodoc:
        const_name =~ /\A(?:::)?[A-Z]\w*(?:::[A-Z]\w*)*\z/
      end

      # helper to partition an array of source files into section and
      # defintion files
      def partition(sources) # :nodoc:
        sources.partition do |path|
          basename = File.basename(path)
          extname  = File.extname(path)
          basename[0] == ?_ && basename.chomp(extname) != '_'
        end
      end

      # helper to load each section path into a sections hash; removes the
      # leading - from the path basename to determine the section key.
      def load_sections(paths) # :nodoc:
        sections = {}

        paths.each do |path|
          basename = File.basename(path)
          extname  = File.extname(path)
          key = basename[1, basename.length - extname.length - 1]
          sections[key] = File.read(path)
        end

        sections
      end

      # helper to load and parse a definition file
      def load_definition(path) # :nodoc:
        extname = File.extname(path)
        name    = File.basename(path).chomp(extname)
        desc, signature, body = parse_definition(File.read(path))

        [desc, parse_method_name(name), signature, method_body(body, extname)]
      rescue CommandError
        err = CommandError.new("#{$!.message} (#{path.inspect})")
        err.set_backtrace($!.backtrace)
        raise err
      end

      # helper to reformat special basenames (in particular -check and -bang)
      # to their corresponding method_name
      def parse_definition(str) # :nodoc:
        head, body = str.split(/^--.*\n/, 2)
        head, body = '', head if body.nil?

        found_signature = false
        signature, desc = head.split("\n").partition do |line|
          found_signature = true if line =~ /^\s*\(.*?\)/
          found_signature
        end

        [desc.join("\n"), found_signature ? signature.join("\n") : '()', body.to_s]
      end

      # helper to reformat special basenames (in particular -check and -bang)
      # to their corresponding method_name
      def parse_method_name(basename) # :nodoc:
        case basename
        when /-check\z/ then basename.sub(/-check$/, '?')
        when /-bang\z/  then basename.sub(/-bang$/, '!')
        when /-eq\z/    then basename.sub(/-eq$/, '=')
        when /\A\w+\z/  then basename
        else raise CommandError.new("invalid method name: #{basename.inspect}")
        end
      end

      # helper to reformat a definition body according to a given extname.  rb
      # content is rstripped to improve formatting.  erb content is compiled
      # and the source is placed as a comment before it (to improve
      # debugability).
      def method_body(body, extname) # :nodoc:
        case extname
        when '.erb'
          source = "#  #{body.gsub(/\n/, "\n#  ")}"
          compiler = ERB::Compiler.new('<>')
          compiler.put_cmd = "write"
          compiler.insert_cmd = "write"
          code = [compiler.compile(body)].flatten.first

          "#{source}\n#{code}".gsub(/^(\s*)/) do |m| 
            indent = 2 + $1.length - ($1.length % 2)
            ' ' * indent
          end

        when '.rb'
          body.rstrip

        else
          raise CommandError.new("invalid definition format: #{extname.inspect}")
        end
      end

      # helper to nest a module body within a const_name.  documentation
      # can be provided for the innermost constant.
      def module_nest(const_name, body, inner_doc=nil) # :nodoc:
        body = body.strip.split("\n")

        const_name.split(/::/).reverse_each do |name|
          body.collect! {|line| line.empty? ? line : "  #{line}" }

          body.unshift "module #{name}"
          body.push    "end"

          # prepend the inner doc to the innermost const
          if inner_doc
            body = inner_doc.strip.split("\n") + body
            inner_doc = nil
          end
        end

        body.join("\n")
      end

      # Returns the code for a const_name module as defined by the source
      # files.
      def build(const_name, sources)
        section_paths, definition_paths = partition(sources)
        sections    = load_sections(section_paths)
        definitions = definition_paths.collect {|path| load_definition(path) }

        body = eval DEFINITION_TEMPLATE, binding, __FILE__, DEFINITION_TEMPLATE_LINE
        code = eval MODULE_TEMPLATE, binding, __FILE__, MODULE_TEMPLATE_LINE

        code
      end

      # :stopdoc:
      MODULE_TEMPLATE_LINE = __LINE__ + 2
      MODULE_TEMPLATE = ERB.new(<<-DOC, nil, '<>').src
# Generated by Linecook
<%= sections['header'] %>

<%= module_nest(const_name, body, sections['doc']) %>

<%= sections['footer'] %>
DOC

      DEFINITION_TEMPLATE_LINE = __LINE__ + 2
      DEFINITION_TEMPLATE = ERB.new(<<-DOC, nil, '<>').src
<%= sections['head'] %>
<% definitions.each do |desc, method_name, signature, method_body| %>
<% desc.split("\n").each do |line| %>
# <%= line %><% end %>
def <%= method_name %><%= signature %>
<%= method_body %>

  _chain_proxy_
end

def _<%= method_name %>(*args, &block) # :nodoc:
  str = capture { <%= method_name %>(*args, &block) }
  str.strip!
  str
end
<% end %>
<%= sections['foot'] %>
DOC
      # :startdoc:
    end
  end
end