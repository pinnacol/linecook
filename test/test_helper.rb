require 'rubygems'
require 'bundler'
Bundler.setup

require 'shell_test/unit'

if name = ENV['NAME']
  ARGV << "--name=#{name}"
end
