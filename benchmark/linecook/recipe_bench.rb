require File.expand_path('../../benchmark_helper', __FILE__)
require 'linecook/test'

class RecipeBench < Test::Unit::TestCase
  include Linecook::Test
  include Benchmark
  
  Package = Linecook::Package
  Recipe = Linecook::Recipe
  
  attr_accessor :package, :recipe
  
  def setup
    super
    @package = Package.new
    @recipe  = package.setup_recipe
  end
  
  def test_capture_by_proxy_speed
    bm(20) do |x|
      n = 10
      x.report("#{n}k capture_str") do
        (n * 1000).times do
          recipe.capture_str { }
        end
      end
      
      x.report("#{n}k callback") do
        (n * 1000).times do
          recipe.callback('name') { }
        end
      end
    end
  end
end