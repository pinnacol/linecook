require 'rubygems'
require 'bundler'
Bundler.setup

require 'linecook/test/unit'

if testcase = ENV['TESTCASE']
  ARGV << "--testcase=#{testcase}"
end

if name = ENV['NAME']
  ARGV << "--name=#{name}"
end
