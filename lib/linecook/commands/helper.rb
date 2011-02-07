require 'linecook/commands/command'
require 'linecook/utils'
require 'erb'

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
    # ::desc-
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
    class Helper < Command
      config :project_dir, '.', :short => :d        # the project directory
      config :force, false, :short => :f, &c.flag   # force creation
      
      include Utils
      
      def const_name?(const_name)
        const_name =~ /\A(?:::)?[A-Z]\w*(?:::[A-Z]\w*)*\z/
      end
      
      def default_sources(const_path)
        pattern = File.join(project_dir, 'helpers', const_path, '*')
        sources = Dir.glob(pattern)
        sources.select {|path| File.file?(path) }
      end
      
      def partition(sources)
        sources.partition {|path| path =~ /\-section\.rb$/ }
      end
      
      def load_sections(paths)
        sections = {}
        
        paths.each do |path|
          key = File.basename(path).chomp!('-section.rb')
          sections[key.to_sym] = File.read(path)
        end
        
        sections
      end
      
      def load_definitions(paths)
        paths.collect do |path|
          extname = File.extname(path)
          name    = File.basename(path).chomp(extname)
          desc, signature, body = parse_definition(File.read(path))
          
          name = method_name(name)
          body = method_body(body, extname)
          
          eval DEF_TEMPLATE, binding, __FILE__, DEF_TEMPLATE_LINE
        end
      end
      
      def parse_definition(str)
        head, body = str.split(/^--.*\n/, 2)
        head, body = '', head if body.nil?
        
        found_signature = false
        signature, desc = head.split("\n").partition do |line|
          found_signature = true if line =~ /^\s*\(.*?\)/
          found_signature
        end
        
        [desc, signature.join("\n"), body]
      end
      
      def method_name(name)
        case name
        when /-check$/ then name.sub(/-check$/, '?')
        when /-bang$/  then name.sub(/-bang$/, '!')
        else name
        end
      end
      
      def method_body(body, extname)
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
          body
          
        else
          raise "invalid definition format: #{extname.inspect}"
        end
      end
      
      def build(const_name, sources)
        section_paths, definition_paths = partition(sources)
        
        sections = load_sections(section_paths)
        definitions = load_definitions(definition_paths)
        
        body = "#{sections[:head]}#{definitions.join("\n")}#{sections[:foot]}".split("\n")
        const_name.split(/::/).reverse_each do |name|
          body.collect! {|line| "  #{line}" }
          body.unshift "module #{name}"
          body.push    "end"
        end
        
        eval MODULE_TEMPLATE, binding, __FILE__, MODULE_TEMPLATE_LINE
      end
      
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
        
        if File.exists?(target) && !force
          raise CommandError, "already exists: #{target}"
        end
        
        log :create, const_name
        content = build(const_name, sources)
        
        target_dir = File.dirname(target)
        unless File.exists?(target_dir)
          FileUtils.mkdir_p(target_dir) 
        end

        File.open(target, 'w') {|io| io << content }
      end
      
      MODULE_TEMPLATE_LINE = __LINE__ + 2
      MODULE_TEMPLATE = ERB.new(<<-DOC, nil, '<>').src
require 'erb'
<%= sections[:header] %>

# Generated by Linecook, do not edit.
<% body.each do |line| %>
<%= line %>

<% end %>

<%= sections[:footer] %>
DOC
  
      DEF_TEMPLATE_LINE = __LINE__ + 2
      DEF_TEMPLATE = ERB.new(<<-DOC, nil, '<>').src
<% desc.each do |line| %>
# <%= line %>
<% end %>
def <%= name %><%= signature %>
<%= body %>

  nil
end

def _<%= name %>(*args, &block) # :nodoc:
  capture { <%= name %>(*args, &block) }
end
DOC
    end
  end
end