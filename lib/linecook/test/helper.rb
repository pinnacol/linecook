require 'linecook/test'
require 'linecook/recipe'

module Linecook
  module Test
    module Helper
      include Linecook::Test
      
      attr_reader :recipe

      def setup
        super
        @recipe = Linecook::Recipe.new.extend helper
      end
      
      def helper
        raise NotImplementedError
      end

      def assert_recipe(expected, &block)
        recipe.instance_eval(&block)
        assert_output_equal expected, recipe.result
      end

      def assert_content(expected, name)
        recipe.close

        source_path = recipe.registry.invert[name]
        assert_output_equal expected, File.read(source_path)
      end
    end
  end
end