require 'linecook/commands/command_error'
require 'configurable'
require 'fileutils'
require 'erb'
require 'ostruct'

module Linecook
  module Commands
    
    # ::desc dir
    #
    # Initializes a linecook scaffold in the specified directory.  This
    # initializer is currently very basic; it is not a true generator.
    # 
    class Init
      extend Lazydoc::Attributes
      include Configurable
      
      lazy_attr :desc
      config :force, false, :short => :f, &c.flag   # force creation
      
      def initialize(config)
        initialize_config(config)
      end
      
      def source_dir
        @source_dir ||= File.expand_path('../../../../templates', __FILE__)
      end
      
      def log(action, msg)
        puts("      %s  %s" % [action, msg])
      end
      
      def call(argv)
        project_dir  = File.expand_path(argv[0])
        
        prepare project_dir
        template project_dir
      end
      
      def prepare(project_dir)
        if File.exists?(project_dir)
          unless force
            raise CommandError.new("already exists: #{project_dir}")
          end

          current_dir = File.expand_path('.')
          unless project_dir.index(current_dir) == 0 && project_dir.length > current_dir.length
            raise CommandError.new("cannot force creation of current or parent directory (safety issue)")
          end

          FileUtils.rm_rf(project_dir)
        end
      end
      
      def template(project_dir, project_name=nil)
        project_name ||= File.basename(project_dir)
        context = OpenStruct.new(:project_name => project_name).send(:binding)
        
        #
        # Copy template files into place
        #
        
        Dir.glob("#{source_dir}/**/*").each do |source|
          if File.directory?(source)
            next
          end

          path = source[(source_dir.length + 1)..-1]
          path = path.sub('project_name', project_name).sub(/^_/, '.')
          target = File.join(project_dir, path)

          log :create, path

          target_dir = File.dirname(target)
          unless File.exists?(target_dir)
            FileUtils.mkdir_p(target_dir)
          end

          File.open(target, 'w') do |io|
            erb = ERB.new(File.read(source), nil, '<>')
            erb.filename = source
            io << erb.result(context)
          end
        end

        # Link up scripts into vbox
        source = File.join(project_dir, 'scripts')
        target = File.join(project_dir, 'vbox/scripts')
        FileUtils.ln_s source, target
      end
    end
  end
end
      