require 'rubygems'
require 'bundler'
Bundler.setup

require 'linecook/test/unit'

if name = ENV['NAME']
  ARGV << "--name=#{name}"
end
