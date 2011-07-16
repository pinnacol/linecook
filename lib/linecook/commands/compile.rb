module Linecook
  module Commands
    # ::desc compile recipes, helpers, packages
    class Compile < Command
      def process(a='A', b='B', c='C')
        puts "got: #{a} #{b} #{c}"
      end
    end
  end
end