require 'shell_test'
require 'linecook/recipe'

module Linecook
  module Test
    include ShellTest

    def use_helpers(*helpers)
      @helpers = helpers
    end

    def helpers
      @helpers ||= []
    end

    def setup_package(env={})
      @package = Package.new(env)
    end

    def package
      @package ||= setup_package
    end

    def setup_recipe(&block)
      recipe = Recipe.new(package)
      helpers.each {|helper| recipe.extend helper }
      recipe.instance_eval(&block) if block_given?
      @recipe = recipe
    end

    def recipe
      @recipe ||= setup_recipe
    end

    def assert_recipe(expected, recipe=setup_recipe, &block)
      recipe.instance_eval(&block) if block_given?
      assert_str_equal expected, recipe._result_
      recipe
    end

    def assert_recipe_matches(expected, recipe=setup_recipe, &block)
      recipe.instance_eval(&block) if block_given?
      assert_str_match expected, recipe._result_
      recipe
    end
  end
end