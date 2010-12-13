require 'tap/generator/base'
require 'fileutils'

module LineCook
  module Generators
    # :startdoc::generator 
    class Cookbook < Tap::Generator::Base
    
      # The generator will receive the inputs on the command line, and
      # m, a Manifest object that records the actions of this method.
      def manifest(m, root='.', project_name=nil)
        r = destination_root.root(root)
        project_name = File.basename(r.path) if project_name == nil
        
        m.directory r.path('attributes')
        m.directory r.path('helpers')
        m.directory r.path('recipes')
        m.directory r.path('scripts')
        
        template_files do |source, target|
          target = r.path target.sub('project_name', project_name).sub(/^_/, '.')
          m.template(target, source, :project_name => project_name)
        end
        
        m.directory r.path('vbox/log')
        m.on(:generate) { 
          unless File.exists?(r.path('vbox/scripts'))
            FileUtils.ln_s(r.path('scripts'), r.path('vbox/scripts'))
          end
        }
      end
    end 
  end
end
