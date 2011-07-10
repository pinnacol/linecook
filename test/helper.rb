require 'rubygems'
require 'bundler'
Bundler.setup

require 'test/unit'

if name = ENV['NAME']
  ARGV << "--name=#{name}"
end
