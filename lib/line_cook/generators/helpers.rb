require 'tap/generator/base'

module LineCook
  module Generators
    # :startdoc::generator 
    class Helpers < Tap::Generator::Base
      Constant = Tap::Env::Constant
    
      helper do
        def method_name(name)
          case name
          when /_check$/ then name.sub(/_check$/, '?')
          when /_bang$/  then name.sub(/_bang$/, '!')
          else name
          end
        end
      end
      
      def manifest(m, dir='helpers', base_path='')
        dirs, paths = Dir.glob("#{dir}/*").partition {|path| File.directory?(path) }
      
        # Recursively generate modules
        dirs.each do |path|
          manifest(m, path, File.join(base_path, File.basename(path)))
        end
      
        # Generate the current module, if necessary
        unless paths.empty?
          const = Constant.new(base_path.camelize)
          sections, definitions = paths.partition {|path| File.basename(path)[0] == ?_ }
        
          m.directory "lib"
          m.template File.join("lib", "#{const.path}.rb"), 'helpers.erb', {
            :sections => load_sections(sections),
            :definitions => definitions.collect {|path| definition(path) },
            :const => const
          }
        end
      end
    
      def load_sections(paths)
        sections = {}
        paths.each do |path|
          key = File.basename(path)[1..-1]
          key.chomp! File.extname(path)
          sections[key.to_sym] = File.read(path)
        end
        sections
      end
    
      def definition(path)
        extname = File.extname(path)
      
        name = File.basename(path).chomp(extname)
        head, body = File.read(path).split(/^--.*\n/, 2)
        head, body = '', head if body.nil?
      
        found_signature = false
        signature, desc = head.split("\n").partition do |line|
          found_signature = true if line =~ /^\s*\(.*?\)/
          found_signature
        end
      
        attrs = {
          :name => name, 
          :desc => desc.join(' '),
          :signature => signature.join("\n"),
          :body => body
        }
      
        case extname
        when '.rb'
          rb_templater.build(attrs, rb_template_path)
        when '.erb'
          erb_templater.build(attrs, erb_template_path)
        else
          raise "invalid definition: #{path}"
        end
      end
    
      def rb_template_path
        @rb_template_path ||= template_root.path('_rb.erb')
      end
    
      def rb_templater
        @rb_templater ||= Tap::Templater.new(File.read(rb_template_path)).extend(Helper)
      end
    
      def erb_template_path
        @erb_template_path ||= template_root.path('_erb.erb')
      end
    
      def erb_templater
        @erb_templater ||= Tap::Templater.new(File.read(erb_template_path)).extend(Helper)
      end
    end 
  end
end
