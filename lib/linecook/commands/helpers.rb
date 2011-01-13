require 'linecook/commands/helper'

module Linecook
  module Commands
    
    # ::desc generates all helpers
    #
    # Generates helpers that match the input patterns (by default all,
    # helpers).
    #
    class Helpers < Helper
      def process
        helpers_dir = File.expand_path('helpers', cookbook_dir)

        sources = {}
        Dir.glob("#{helpers_dir}/*/**/*").each do |source|
          next if File.directory?(source)
          (sources[File.dirname(source)] ||= []) << source
        end

        sources.each_pair do |dir, sources|
          name = dir[(helpers_dir.length+1)..-1]
          super(name, *sources)
        end
      end
    end
  end
end