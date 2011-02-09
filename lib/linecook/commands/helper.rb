require 'linecook/commands/command'
require 'linecook/utils'
require 'erb'
require 'fileutils'

module Linecook
  module Commands
    
    # ::desc generates a helper module
    #
    # Generates the specified helper module from a set of source files.  Each
    # source file becomes a method in the module, named after the source file
    # itself.
    #
    # The helper module will be generated under the lib directory in a file
    # corresponding to const_name (which can also be a constant path).  By
    # default, all files under the corresponding helpers directory will be
    # used as sources.  For example these are equivalent and produce the
    # Const::Name module in 'lib/const/name.rb':
    #
    #   % linecook helper Const::Name
    #   % linecook helper const/name
    #   % linecook helper const/name helpers/const/name/*
    #
    class Helper < Command
      config :project_dir, '.', :short => :d        # the project directory
      config :force, false, :short => :f, &c.flag   # force creation
      
      include Utils
      
      def process(const_name, *sources)
        const_path = underscore(const_name)
        const_name = camelize(const_path)
        
        unless const_name?(const_name)
          raise "invalid constant name: #{const_name.inspect}"
        end
        
        sources = default_sources(const_path) if sources.empty?
        target  = File.expand_path(File.join('lib', "#{const_path}.rb"), project_dir)
        
        if sources.empty?
          raise CommandError, "no sources specified (and none found under 'helpers/#{const_path}')"
        end
        
        if force || !FileUtils.uptodate?(target, sources)
          log :create, const_name
          content = build(const_name, sources)
          
          target_dir = File.dirname(target)
          unless File.exists?(target_dir)
            FileUtils.mkdir_p(target_dir) 
          end
          
          File.open(target, 'w') {|io| io << content }
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
        sources.partition {|path| path =~ /\-section\.rb$/ }
      end
      
      # helper to load each section path into a sections hash; strips the
      # -section off the path name to determine the section key.
      def load_sections(paths) # :nodoc:
        sections = {}
        
        paths.each do |path|
          key = File.basename(path).chomp!('-section.rb')
          sections[key] = File.read(path)
        end
        
        sections
      end
      
      # helper to load and parse a definition file
      def load_definition(path) # :nodoc:
        extname = File.extname(path)
        name    = File.basename(path).chomp(extname)
        desc, signature, body = parse_definition(File.read(path))
        
        [desc, method_name(name), signature, method_body(body, extname)]
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
        
        [desc.join("\n"), found_signature ? signature.join("\n") : '()', body]
      end
      
      # helper to reformat special basenames (in particular -check and -bang)
      # to their corresponding method_name
      def method_name(basename) # :nodoc:
        case basename
        when /-check$/ then basename.sub(/-check$/, '?')
        when /-bang$/  then basename.sub(/-bang$/, '!')
        else basename
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
          code   = ERB.new(body, nil, '<>').src
          
          if code =~ /\A_erbout = '';\s*(.*?)\s*_erbout\z/m
            code = $1
          end
          
          "#{source}\n#{code}".gsub(/^(\s*)/) do |m| 
            indent = 2 + $1.length - ($1.length % 2)
            ' ' * indent
          end
          
        when '.rb'
          body.rstrip
          
        else
          raise "invalid definition format: #{extname.inspect}"
        end
      end
      
      # helper to nest a module body within a const_name.
      def module_nest(const_name, body) # :nodoc:
        body = body.strip.split("\n")
        
        const_name.split(/::/).reverse_each do |name|
          body.collect! {|line| "  #{line}" }
          body.unshift "module #{name}"
          body.push    "end"
        end
        
        body.join("\n")
      end
      
      # Returns the code for a const_name module as defined by the source
      # files.
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
      # Check and bang methods can be specified by adding -check and -bang to
      # the end of the file name.  These extensions are stripped off like:
      #
      #   [file-check.erb]   # => def file? ...
      #   [make-bang.rb]     # => def make! ...
      #
      # == Section Files
      #
      # Special section files can be used to define non-standard code in the
      # following places:
      #
      #   [:header]
      #   module Name
      #     [:head]
      #     ...
      #     [:foot]
      #   end
      #   [:footer]
      #
      # Section files are defined by adding -section.rb at the end of the file
      # name (like header-section.rb) and are not processed like other source
      # files; the contents are directly transcribed.
      #
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
require 'erb'
<%= sections['header'] %>

# Generated by Linecook, do not edit.
<%= module_nest(const_name, body) %>

<%= sections['footer'] %>
DOC

      DEFINITION_TEMPLATE_LINE = __LINE__ + 2
      DEFINITION_TEMPLATE = ERB.new(<<-DOC, nil, '<>').src
<%= sections['head'] %>

<% definitions.each do |desc, method_name, signature, body| %>
<% desc.split("\n").each do |line| %>
# <%= line %>
<% end %>
def <%= method_name %><%= signature %>
<%= body %>

  nil
end

def _<%= method_name %>(*args, &block) # :nodoc:
  capture { <%= method_name %>(*args, &block) }
end
<% end %>

<%= sections['foot'] %>
DOC
    # :startdoc:
    end
  end
end